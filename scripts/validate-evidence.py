#!/usr/bin/env python3
import argparse
import datetime
import glob
import json
import os
import sys


VALID_RESULTS = {"pass", "fail", "skipped", "not_certified"}
VALID_LEVELS = {
    "declared",
    "smoke-built",
    "runtime-certified",
    "release-gated",
}
LEVEL_ORDER = {
    "declared": 0,
    "smoke-built": 1,
    "runtime-certified": 2,
    "release-gated": 3,
}
REQUIRED_FIELDS = (
    "schema_version",
    "repo",
    "lane",
    "commit_sha",
    "workflow_name",
    "runner_os",
    "backend",
    "result",
    "timestamp",
    "artifact_path",
)


def parse_bool(value):
    return str(value).strip().lower() in ("1", "true", "yes", "on")


def parse_args():
    parser = argparse.ArgumentParser(
        description="Validate ofxGgml Evidence Schema v1 artifacts."
    )
    parser.add_argument("--evidence-path", required=True)
    parser.add_argument("--require-evidence-file", default="false")
    parser.add_argument("--require-schema-valid", default="false")
    parser.add_argument("--allowed-schema-versions", default="1")
    parser.add_argument("--require-current-sha", default="false")
    parser.add_argument("--expected-commit-sha", default="")
    parser.add_argument("--require-freshness", default="false")
    parser.add_argument("--max-evidence-age-hours", default="0")
    parser.add_argument("--required-backend", default="")
    parser.add_argument("--required-result", default="")
    parser.add_argument("--minimum-certification-level", default="")
    parser.add_argument("--quality-report-path", default="")
    parser.add_argument(
        "--issue-label",
        default="Evidence schema validation issues",
    )
    parser.add_argument(
        "--advisory-message",
        default="Evidence issues are advisory because enforcement inputs are false.",
    )
    return parser.parse_args()


def as_records(data):
    if isinstance(data, list):
        return data
    return [data]


def non_empty_string(value):
    return isinstance(value, str) and bool(value.strip())


def parse_timestamp(value):
    if not isinstance(value, str) or not value.strip():
        return None
    try:
        parsed = datetime.datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=datetime.timezone.utc)
    return parsed.astimezone(datetime.timezone.utc)


def find_evidence_files(evidence_path):
    evidence_files = sorted(set(glob.glob(evidence_path, recursive=True)))
    if not evidence_files and os.path.isfile(evidence_path):
        evidence_files = [evidence_path]
    return evidence_files


def main():
    args = parse_args()
    require_evidence_file = parse_bool(args.require_evidence_file)
    require_schema_valid = parse_bool(args.require_schema_valid)
    require_current_sha = parse_bool(args.require_current_sha)
    require_freshness = parse_bool(args.require_freshness)
    expected_commit_sha = args.expected_commit_sha.strip()
    required_backend = args.required_backend.strip()
    required_result = args.required_result.strip()
    minimum_certification_level = args.minimum_certification_level.strip()
    allowed_versions = {
        item.strip()
        for item in args.allowed_schema_versions.split(",")
        if item.strip()
    }

    try:
        max_evidence_age_hours = float(args.max_evidence_age_hours.strip())
    except ValueError:
        print(
            f"max_evidence_age_hours must be numeric: {args.max_evidence_age_hours}",
            file=sys.stderr,
        )
        return 1

    evidence_files = find_evidence_files(args.evidence_path)
    if not evidence_files:
        message = f"No evidence files matched: {args.evidence_path}"
        if require_evidence_file:
            print(message, file=sys.stderr)
            return 1
        print(message)
        return 0

    errors = []
    matching_records = 0
    quality_passed = 0
    quality_total = 0
    quality_rows = []
    require_matching_record = any(
        (required_backend, required_result, minimum_certification_level)
    )

    if required_result and required_result not in VALID_RESULTS:
        errors.append(f"required_result must be one of: {', '.join(sorted(VALID_RESULTS))}")
    if minimum_certification_level and minimum_certification_level not in VALID_LEVELS:
        errors.append(
            "minimum_certification_level must be one of: "
            f"{', '.join(sorted(VALID_LEVELS))}"
        )

    def validate_record(path, index, record):
        nonlocal matching_records, quality_passed, quality_total
        prefix = f"{path}[{index}]"
        if not isinstance(record, dict):
            errors.append(f"{prefix} must be a JSON object")
            return

        for field in REQUIRED_FIELDS:
            if field not in record:
                errors.append(f"{prefix} missing required field: {field}")

        version = str(record.get("schema_version", "")).strip()
        if allowed_versions and version not in allowed_versions:
            errors.append(f"{prefix} has unsupported schema_version: {version}")

        for field in (
            "repo",
            "lane",
            "commit_sha",
            "workflow_name",
            "runner_os",
            "backend",
            "artifact_path",
        ):
            if field in record and not non_empty_string(record[field]):
                errors.append(f"{prefix}.{field} must be a non-empty string")

        if "commit_sha" in record and non_empty_string(record["commit_sha"]):
            if len(record["commit_sha"]) < 7:
                errors.append(f"{prefix}.commit_sha must be at least 7 characters")
            elif require_current_sha and expected_commit_sha:
                actual_sha = record["commit_sha"].lower()
                expected_sha = expected_commit_sha.lower()
                if not (
                    actual_sha == expected_sha
                    or actual_sha.startswith(expected_sha)
                    or expected_sha.startswith(actual_sha)
                ):
                    errors.append(
                        f"{prefix}.commit_sha {record['commit_sha']} does not match "
                        f"expected {expected_commit_sha}"
                    )

        result = record.get("result")
        if result is not None and result not in VALID_RESULTS:
            errors.append(
                f"{prefix}.result must be one of: {', '.join(sorted(VALID_RESULTS))}"
            )

        level = record.get("certification_level")
        if level is not None and level not in VALID_LEVELS:
            errors.append(
                f"{prefix}.certification_level must be one of: "
                f"{', '.join(sorted(VALID_LEVELS))}"
            )

        parsed_timestamp = None
        if "timestamp" in record:
            parsed_timestamp = parse_timestamp(record["timestamp"])
            if parsed_timestamp is None:
                errors.append(f"{prefix}.timestamp must be an ISO 8601 date-time")
            elif require_freshness:
                if max_evidence_age_hours <= 0:
                    errors.append(
                        f"{prefix} cannot check freshness without "
                        "max_evidence_age_hours greater than 0"
                    )
                else:
                    now = datetime.datetime.now(datetime.timezone.utc)
                    age_hours = (now - parsed_timestamp).total_seconds() / 3600
                    if age_hours < 0:
                        errors.append(f"{prefix}.timestamp is in the future")
                    elif age_hours > max_evidence_age_hours:
                        errors.append(
                            f"{prefix} evidence is stale: {age_hours:.2f}h old, "
                            f"limit is {max_evidence_age_hours:.2f}h"
                        )

        tool_versions = record.get("tool_versions")
        if tool_versions is not None and not isinstance(tool_versions, dict):
            errors.append(f"{prefix}.tool_versions must be an object when present")

        if require_matching_record:
            backend_matches = (
                not required_backend
                or str(record.get("backend", "")).strip() == required_backend
            )
            result_matches = (
                not required_result
                or str(record.get("result", "")).strip() == required_result
            )
            level_value = str(record.get("certification_level", "")).strip()
            level_matches = (
                not minimum_certification_level
                or (
                    level_value in LEVEL_ORDER
                    and LEVEL_ORDER[level_value] >= LEVEL_ORDER[minimum_certification_level]
                )
            )
            if backend_matches and result_matches and level_matches:
                matching_records += 1

        checks = []
        checks.append(
            (
                "schema_core",
                all(field in record for field in REQUIRED_FIELDS)
                and str(record.get("schema_version", "")).strip() in allowed_versions
                and record.get("result") in VALID_RESULTS,
            )
        )

        if expected_commit_sha:
            commit_sha = str(record.get("commit_sha", "")).strip().lower()
            expected_sha = expected_commit_sha.lower()
            checks.append(
                (
                    "current_sha",
                    bool(commit_sha)
                    and (
                        commit_sha == expected_sha
                        or commit_sha.startswith(expected_sha)
                        or expected_sha.startswith(commit_sha)
                    ),
                )
            )

        if max_evidence_age_hours > 0:
            if parsed_timestamp is None:
                checks.append(("freshness", False))
            else:
                age_hours = (
                    datetime.datetime.now(datetime.timezone.utc) - parsed_timestamp
                ).total_seconds() / 3600
                checks.append(("freshness", 0 <= age_hours <= max_evidence_age_hours))

        if required_backend:
            checks.append(("backend_match", record.get("backend") == required_backend))
        if required_result:
            checks.append(("result_match", record.get("result") == required_result))
        if minimum_certification_level:
            level_value = str(record.get("certification_level", "")).strip()
            checks.append(
                (
                    "certification_level",
                    level_value in LEVEL_ORDER
                    and LEVEL_ORDER[level_value] >= LEVEL_ORDER[minimum_certification_level],
                )
            )

        checks.extend(
            (
                ("command", non_empty_string(record.get("command"))),
                (
                    "tool_versions",
                    isinstance(record.get("tool_versions"), dict)
                    and bool(record.get("tool_versions")),
                ),
                ("device_summary", bool(record.get("device_summary"))),
                ("artifact_path", non_empty_string(record.get("artifact_path"))),
            )
        )

        record_passed = sum(1 for _, passed in checks if passed)
        record_total = len(checks)
        quality_passed += record_passed
        quality_total += record_total
        quality_rows.append((prefix, record_passed, record_total, checks))

    for path in evidence_files:
        try:
            with open(path, "r", encoding="utf-8-sig") as handle:
                data = json.load(handle)
        except Exception as exc:
            errors.append(f"{path} could not be parsed as JSON: {exc}")
            continue

        for index, record in enumerate(as_records(data)):
            validate_record(path, index, record)

    if require_matching_record and matching_records == 0:
        filters = []
        if required_backend:
            filters.append(f"backend={required_backend}")
        if required_result:
            filters.append(f"result={required_result}")
        if minimum_certification_level:
            filters.append(f"certification_level>={minimum_certification_level}")
        errors.append(f"No evidence record matched required filters: {', '.join(filters)}")

    if errors:
        print(f"{args.issue_label}:")
        for error in errors:
            print(f"- {error}")
        if (
            require_schema_valid
            or require_current_sha
            or require_freshness
            or require_matching_record
        ):
            return 1
        print(args.advisory_message)
        return 0

    if quality_total:
        quality_score = round((quality_passed / quality_total) * 100, 2)
        print(
            f"Evidence quality score: {quality_score}% "
            f"({quality_passed}/{quality_total} checks passed)."
        )

    if args.quality_report_path:
        report_dir = os.path.dirname(args.quality_report_path)
        if report_dir:
            os.makedirs(report_dir, exist_ok=True)
        with open(args.quality_report_path, "w", encoding="utf-8") as handle:
            handle.write("# Evidence Quality Report\n\n")
            if quality_total:
                quality_score = round((quality_passed / quality_total) * 100, 2)
                handle.write(
                    f"Overall score: {quality_score}% "
                    f"({quality_passed}/{quality_total} checks passed).\n\n"
                )
            for prefix, record_passed, record_total, checks in quality_rows:
                handle.write(f"## {prefix}\n\n")
                handle.write(f"Score: {record_passed}/{record_total}\n\n")
                for name, passed in checks:
                    marker = "pass" if passed else "missing"
                    handle.write(f"- {name}: {marker}\n")
                handle.write("\n")
        print(f"Wrote evidence quality report: {args.quality_report_path}")

    print(f"Validated {len(evidence_files)} evidence file(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
