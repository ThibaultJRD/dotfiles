#!/bin/bash

# Simple test script for cleanup tool
echo "Testing cleanup tool compilation and basic functionality..."

# Test if Go is available
if ! command -v go >/dev/null 2>&1; then
    echo "❌ Go not found"
    exit 1
fi

# Test compilation
echo "🔨 Building cleanup tool..."
if go build ./cmd/cleanup-tool; then
    echo "✅ Build successful"
else
    echo "❌ Build failed"
    exit 1
fi

# Test help output
echo "📖 Testing help output..."
if ./cleanup-tool --help >/dev/null 2>&1; then
    echo "✅ Help command works"
else
    echo "❌ Help command failed"
    exit 1
fi

# Test that binary exists
if [[ -f "./cleanup-tool" ]]; then
    echo "✅ Binary created successfully"
else
    echo "❌ Binary not found"
    exit 1
fi

echo "🎉 All tests passed!"
echo "💡 To test interactively: ./cleanup-tool"