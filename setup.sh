#!/bin/bash
set -e

echo "🚀 Setting up StartupApp..."

# Install XcodeGen if not present
if ! command -v xcodegen &> /dev/null; then
    echo "Installing XcodeGen..."
    if command -v brew &> /dev/null; then
        brew install xcodegen
    else
        echo "Please install XcodeGen: https://github.com/yonaskolb/XcodeGen"
        exit 1
    fi
fi

# Generate Xcode project
echo "Generating Xcode project..."
xcodegen generate

echo ""
echo "✅ Done! Next steps:"
echo ""
echo "1. Open StartupApp.xcodeproj in Xcode"
echo "2. Go to Google Cloud Console → Create OAuth 2.0 Client ID for iOS"
echo "3. Replace in StartupApp/Info.plist:"
echo "   - YOUR_GOOGLE_CLIENT_ID  → your actual Client ID"
echo "   - YOUR_REVERSED_CLIENT_ID → reversed Client ID (e.g. com.googleusercontent.apps.XXXXX)"
echo "4. Select your team in Xcode → Signing & Capabilities"
echo "5. Build & Run!"
