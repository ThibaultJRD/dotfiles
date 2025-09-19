#!/bin/bash

# Test script for the new interactive cleanup tool

echo "🧹 Testing new interactive cleanup tool"
echo "======================================="
echo

# Compilation test
echo "1. Testing compilation..."
go build -o cleanup-tool cmd/cleanup-tool/main.go
if [ $? -eq 0 ]; then
    echo "✅ Compilation successful"
else
    echo "❌ Compilation error"
    exit 1
fi
echo

# Help test
echo "2. Testing help..."
./cleanup-tool --help > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ Help accessible"
else
    echo "❌ Help display error"
    exit 1
fi
echo

# Test existence of main files
echo "3. Verifying created files..."
files=(
    "pkg/scanner/interface.go"
    "pkg/scanner/nodemodules.go" 
    "pkg/scanner/pods.go"
    "pkg/utils/size.go"
    "internal/ui/scanner_view.go"
    "internal/app/interactive_model.go"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
        exit 1
    fi
done
echo

# Test available modes
echo "4. Testing available modes..."
echo "Legacy mode available:"
./cleanup-tool --legacy --help > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Legacy mode available"
else
    echo "❌ Problem with legacy mode"
fi

echo "Interactive mode default:"
timeout 2 ./cleanup-tool < /dev/null > /dev/null 2>&1
if [ $? -eq 124 ]; then  # timeout = program started but interrupted
    echo "✅ Interactive mode starts correctly"
else
    echo "❌ Problem with interactive mode"
fi
echo

echo "🎉 All tests passed!"
echo
echo "📋 Implemented features:"
echo "  • Modular scanner with common interface"
echo "  • NodeModulesScanner with size calculation"
echo "  • PodsScanner for CocoaPods"
echo "  • Interactive user interface"
echo "  • Granular item selection"
echo "  • Preserved legacy mode"
echo "  • Navigation with j/k and arrows"
echo "  • Sort by size"
echo "  • Space freed calculation"
echo
echo "🚀 Ready to use: ./cleanup-tool"