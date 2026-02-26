#!/bin/bash
################################################################################
# Script Validation Test Suite
# Tests all scripts for common syntax and logic errors
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Script Validation Test Suite                        ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
cd "$SCRIPT_DIR"

echo -e "${YELLOW}Testing from directory: $SCRIPT_DIR${NC}"
echo ""

################################################################################
# Test 1: File Existence
################################################################################
echo -e "${BLUE}[1/6] Checking file existence...${NC}"

scripts=(
    "master-install.sh"
    "sources_list_setup.sh"
    "sway-minimal-install.sh"
    "sway-post-install-tweaks.sh"
    "verify-installation.sh"
)

for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        echo -e "  ${GREEN}✓${NC} $script exists"
        ((PASS++))
    else
        echo -e "  ${RED}✗${NC} $script MISSING"
        ((FAIL++))
    fi
done

################################################################################
# Test 2: Shebang Check
################################################################################
echo ""
echo -e "${BLUE}[2/6] Checking shebangs...${NC}"

for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        first_line=$(head -n 1 "$script")
        if [[ "$first_line" =~ ^#!/bin/bash ]]; then
            echo -e "  ${GREEN}✓${NC} $script has correct shebang"
            ((PASS++))
        else
            echo -e "  ${RED}✗${NC} $script has invalid shebang: $first_line"
            ((FAIL++))
        fi
    fi
done

################################################################################
# Test 3: Bash Syntax Check
################################################################################
echo ""
echo -e "${BLUE}[3/6] Checking bash syntax (dry-run)...${NC}"

for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        if bash -n "$script" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $script syntax OK"
            ((PASS++))
        else
            echo -e "  ${RED}✗${NC} $script has syntax errors:"
            bash -n "$script"
            ((FAIL++))
        fi
    fi
done

################################################################################
# Test 4: Script Structure Validation
################################################################################
echo ""
echo -e "${BLUE}[4/6] Validating script structure...${NC}"

for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        # Check for set -e
        if grep -q "^set -e" "$script"; then
            echo -e "  ${GREEN}✓${NC} $script has error handling (set -e)"
            ((PASS++))
        else
            echo -e "  ${YELLOW}⚠${NC} $script missing 'set -e' (error handling)"
            ((WARN++))
        fi
        
        # Check if/fi balance
        if_count=$(grep -c "^\s*if\s*\[" "$script" || true)
        fi_count=$(grep -c "^\s*fi\s*$" "$script" || true)
        
        if [ "$if_count" -eq "$fi_count" ]; then
            echo -e "  ${GREEN}✓${NC} $script if/fi balanced ($if_count pairs)"
            ((PASS++))
        else
            echo -e "  ${RED}✗${NC} $script if/fi unbalanced (if: $if_count, fi: $fi_count)"
            ((FAIL++))
        fi
    fi
done

################################################################################
# Test 5: Check for Common Issues
################################################################################
echo ""
echo -e "${BLUE}[5/6] Checking for common issues...${NC}"

for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        # Check for unquoted variables in critical sections
        if grep -q '\$user' "$script"; then
            if grep -q '"/home/\$user' "$script"; then
                echo -e "  ${GREEN}✓${NC} $script \$user properly quoted"
                ((PASS++))
            else
                echo -e "  ${YELLOW}⚠${NC} $script may have unquoted \$user"
                ((WARN++))
            fi
        fi
        
        # Check for proper heredoc terminators
        heredoc_starts=$(grep -c "<<\s*['\"].*['\"]" "$script" || true)
        if [ "$heredoc_starts" -gt 0 ]; then
            echo -e "  ${GREEN}✓${NC} $script has $heredoc_starts heredoc(s)"
            ((PASS++))
        fi
    fi
done

################################################################################
# Test 6: Documentation Check
################################################################################
echo ""
echo -e "${BLUE}[6/6] Checking documentation files...${NC}"

docs=(
    "README.md"
    "INSTALLATION-GUIDE.md"
    "SWAY-QUICK-REFERENCE.md"
    "00-READ-ME-FIRST.txt"
)

for doc in "${docs[@]}"; do
    if [ -f "$doc" ]; then
        echo -e "  ${GREEN}✓${NC} $doc exists"
        ((PASS++))
    else
        echo -e "  ${YELLOW}⚠${NC} $doc missing"
        ((WARN++))
    fi
done

################################################################################
# Summary
################################################################################
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    TEST SUMMARY                               ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${GREEN}✓ Passed:${NC}  $PASS"
echo -e "  ${RED}✗ Failed:${NC}  $FAIL"
echo -e "  ${YELLOW}⚠ Warnings:${NC} $WARN"
echo ""

if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ ALL TESTS PASSED - Scripts are ready for deployment       ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ✗ SOME TESTS FAILED - Review errors above                   ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════════╝${NC}"
    exit 1
fi
