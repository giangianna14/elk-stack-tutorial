#!/bin/bash

# Test Script untuk ELK Stack Tutorial
# Memvalidasi syntax dan basic functionality semua script

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}  ELK Stack Tutorial - Script Tests${NC}"
echo -e "${GREEN}=======================================${NC}"
echo

# Function to test script syntax
test_script_syntax() {
    local script_name=$1
    echo -n "Testing $script_name syntax... "
    
    if [ -f "$script_name" ]; then
        if bash -n "$script_name" 2>/dev/null; then
            echo -e "${GREEN}✓ PASS${NC}"
            return 0
        else
            echo -e "${RED}✗ FAIL${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ NOT FOUND${NC}"
        return 1
    fi
}

# Function to test script permissions
test_script_permissions() {
    local script_name=$1
    echo -n "Testing $script_name permissions... "
    
    if [ -f "$script_name" ]; then
        if [ -x "$script_name" ]; then
            echo -e "${GREEN}✓ EXECUTABLE${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠ NOT EXECUTABLE${NC}"
            echo "  Making executable..."
            chmod +x "$script_name"
            echo -e "${GREEN}✓ FIXED${NC}"
            return 0
        fi
    else
        echo -e "${RED}✗ NOT FOUND${NC}"
        return 1
    fi
}

# Function to test script help/usage
test_script_help() {
    local script_name=$1
    echo -n "Testing $script_name help... "
    
    if [ -f "$script_name" ]; then
        # Try to get help or usage information
        if grep -q "usage\|help\|Usage\|Help" "$script_name" 2>/dev/null; then
            echo -e "${GREEN}✓ HAS HELP${NC}"
        else
            echo -e "${YELLOW}⚠ NO HELP${NC}"
        fi
        return 0
    else
        echo -e "${RED}✗ NOT FOUND${NC}"
        return 1
    fi
}

# Test all scripts
scripts=(
    "setup.sh"
    "setup-local-cluster.sh"
    "setup-lightweight.sh"
    "uninstall.sh"
)

echo -e "${YELLOW}=== Syntax Tests ===${NC}"
syntax_failures=0
for script in "${scripts[@]}"; do
    if ! test_script_syntax "$script"; then
        syntax_failures=$((syntax_failures + 1))
    fi
done

echo
echo -e "${YELLOW}=== Permission Tests ===${NC}"
permission_failures=0
for script in "${scripts[@]}"; do
    if ! test_script_permissions "$script"; then
        permission_failures=$((permission_failures + 1))
    fi
done

echo
echo -e "${YELLOW}=== Help/Usage Tests ===${NC}"
for script in "${scripts[@]}"; do
    test_script_help "$script"
done

echo
echo -e "${YELLOW}=== Documentation Tests ===${NC}"
docs=(
    "README.md"
    "QUICK_START.md"
    "TUTORIAL_SUMMARY.md"
    "UNINSTALL_GUIDE.md"
)

doc_failures=0
for doc in "${docs[@]}"; do
    echo -n "Testing $doc... "
    if [ -f "$doc" ]; then
        if [ -s "$doc" ]; then
            echo -e "${GREEN}✓ EXISTS${NC}"
        else
            echo -e "${RED}✗ EMPTY${NC}"
            doc_failures=$((doc_failures + 1))
        fi
    else
        echo -e "${RED}✗ MISSING${NC}"
        doc_failures=$((doc_failures + 1))
    fi
done

echo
echo -e "${YELLOW}=== Structure Tests ===${NC}"
directories=(
    "01-openshift"
    "02-beats"
    "03-kafka"
    "04-logstash"
    "05-elasticsearch"
    "06-kibana"
    "07-use-cases"
)

structure_failures=0
for dir in "${directories[@]}"; do
    echo -n "Testing directory $dir... "
    if [ -d "$dir" ]; then
        if [ -f "$dir/README.md" ]; then
            echo -e "${GREEN}✓ EXISTS WITH README${NC}"
        else
            echo -e "${YELLOW}⚠ NO README${NC}"
        fi
    else
        echo -e "${RED}✗ MISSING${NC}"
        structure_failures=$((structure_failures + 1))
    fi
done

echo
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}           Test Results${NC}"
echo -e "${GREEN}=======================================${NC}"

total_failures=$((syntax_failures + permission_failures + doc_failures + structure_failures))

if [ $syntax_failures -eq 0 ]; then
    echo -e "Script Syntax: ${GREEN}✓ All scripts have valid syntax${NC}"
else
    echo -e "Script Syntax: ${RED}✗ $syntax_failures scripts have syntax errors${NC}"
fi

if [ $permission_failures -eq 0 ]; then
    echo -e "Permissions: ${GREEN}✓ All scripts are executable${NC}"
else
    echo -e "Permissions: ${RED}✗ $permission_failures scripts had permission issues${NC}"
fi

if [ $doc_failures -eq 0 ]; then
    echo -e "Documentation: ${GREEN}✓ All documentation files exist${NC}"
else
    echo -e "Documentation: ${RED}✗ $doc_failures documentation files missing/empty${NC}"
fi

if [ $structure_failures -eq 0 ]; then
    echo -e "Directory Structure: ${GREEN}✓ All directories exist${NC}"
else
    echo -e "Directory Structure: ${RED}✗ $structure_failures directories missing${NC}"
fi

echo
if [ $total_failures -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! Tutorial is ready to use.${NC}"
    echo
    echo "Usage:"
    echo "  ./setup.sh                 # Full setup"
    echo "  ./setup-local-cluster.sh   # Local cluster setup"  
    echo "  ./setup-lightweight.sh     # Lightweight setup"
    echo "  ./uninstall.sh             # Complete cleanup"
    exit 0
else
    echo -e "${RED}❌ $total_failures tests failed. Please fix issues before using.${NC}"
    exit 1
fi
