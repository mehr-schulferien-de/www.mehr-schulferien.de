#!/bin/bash

# Test Quality Checker
# Ensures tests run cleanly without warnings, errors, or debug output

set -e

echo "🔍 Checking test quality..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track if any issues are found
ISSUES_FOUND=0

# 1. Check for skipped tests
echo -n "Checking for skipped tests... "
SKIPPED_COUNT=$(grep -r "@tag :skip\|@moduletag :skip\|@tag skip:\|tag :skip" test/ 2>/dev/null | wc -l || echo "0")
if [ "$SKIPPED_COUNT" -gt 0 ]; then
    echo -e "${RED}✗${NC} Found $SKIPPED_COUNT skipped test(s)"
    echo "  Skipped tests found in:"
    grep -r "@tag :skip\|@moduletag :skip\|@tag skip:\|tag :skip" test/ --include="*.exs" | cut -d: -f1 | sort | uniq | sed 's/^/    - /'
    ISSUES_FOUND=1
else
    echo -e "${GREEN}✓${NC} No skipped tests"
fi

# 2. Check for debug output in tests
echo -n "Checking for debug output in tests... "
DEBUG_COUNT=$(grep -r "IO\.puts\|IO\.inspect\|IO\.write\|dbg\(\|:dbg\|Logger\.debug" test/ --include="*.exs" 2>/dev/null | grep -v "^\s*#" | wc -l || echo "0")
if [ "$DEBUG_COUNT" -gt 0 ]; then
    echo -e "${RED}✗${NC} Found $DEBUG_COUNT debug statement(s)"
    echo "  Debug output found in:"
    grep -r "IO\.puts\|IO\.inspect\|IO\.write\|dbg\(\|:dbg\|Logger\.debug" test/ --include="*.exs" | grep -v "^\s*#" | cut -d: -f1 | sort | uniq | sed 's/^/    - /'
    ISSUES_FOUND=1
else
    echo -e "${GREEN}✓${NC} No debug output"
fi

# 3. Check for placeholder tests (assert true)
echo -n "Checking for placeholder tests... "
PLACEHOLDER_COUNT=$(grep -r "assert true" test/ --include="*.exs" 2>/dev/null | wc -l || echo "0")
if [ "$PLACEHOLDER_COUNT" -gt 0 ]; then
    echo -e "${RED}✗${NC} Found $PLACEHOLDER_COUNT placeholder test(s) with 'assert true'"
    echo "  Placeholder tests found in:"
    grep -r "assert true" test/ --include="*.exs" | cut -d: -f1 | sort | uniq | sed 's/^/    - /'
    ISSUES_FOUND=1
else
    echo -e "${GREEN}✓${NC} No placeholder tests"
fi

# 4. Run tests and capture output
echo -n "Running tests to check for clean output... "
TEST_OUTPUT=$(mix test 2>&1 | tee /tmp/test_output.txt)

# Check for warnings in test output (excluding compilation)
WARNING_COUNT=$(echo "$TEST_OUTPUT" | grep -E "\[warning\]|\[error\]" | grep -v "Compiling" | wc -l || echo "0")
if [ "$WARNING_COUNT" -gt 0 ]; then
    echo -e "${RED}✗${NC} Found $WARNING_COUNT warning(s)/error(s) in test output"
    echo "  Sample warnings/errors:"
    echo "$TEST_OUTPUT" | grep -E "\[warning\]|\[error\]" | head -5 | sed 's/^/    /'
    ISSUES_FOUND=1
else
    echo -e "${GREEN}✓${NC} No warnings or errors in test output"
fi

# 5. Check for failures
FAILURE_LINE=$(echo "$TEST_OUTPUT" | grep -E "[0-9]+ tests?, [0-9]+ failures?")
if echo "$FAILURE_LINE" | grep -q "0 failure"; then
    echo -e "${GREEN}✓${NC} All tests passing"
else
    echo -e "${RED}✗${NC} Tests have failures: $FAILURE_LINE"
    ISSUES_FOUND=1
fi

# 6. Check for skipped in output
if echo "$FAILURE_LINE" | grep -q "skipped"; then
    SKIPPED=$(echo "$FAILURE_LINE" | grep -oE "[0-9]+ skipped")
    echo -e "${RED}✗${NC} Tests report: $SKIPPED"
    ISSUES_FOUND=1
else
    echo -e "${GREEN}✓${NC} No skipped tests in output"
fi

# 7. Check for proper logger configuration in test env
echo -n "Checking test logger configuration... "
if grep -q "config :logger, level: :error" config/test.exs; then
    echo -e "${GREEN}✓${NC} Logger properly configured for tests"
else
    echo -e "${YELLOW}⚠${NC} Logger may not be configured to :error level in test.exs"
    echo "  Consider setting: config :logger, level: :error"
fi

# 8. Check for stray console.log or similar in assets
if [ -d "assets" ]; then
    echo -n "Checking for console.log in assets... "
    CONSOLE_COUNT=$(find assets -name "*.js" -o -name "*.ts" | xargs grep -h "console\.\(log\|debug\|info\|warn\)" 2>/dev/null | grep -v "^\s*//" | wc -l || echo "0")
    if [ "$CONSOLE_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}⚠${NC} Found $CONSOLE_COUNT console statement(s) in assets"
    else
        echo -e "${GREEN}✓${NC} No console statements in assets"
    fi
fi

# Summary
echo ""
echo "════════════════════════════════════════"
if [ "$ISSUES_FOUND" -eq 0 ]; then
    echo -e "${GREEN}✅ Test quality check passed!${NC}"
    echo "All tests are clean and ready."
else
    echo -e "${RED}❌ Test quality issues found!${NC}"
    echo "Please fix the issues above before committing."
    exit 1
fi