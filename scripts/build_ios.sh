#!/bin/bash

# AndCo School Transport - iOS Build Script
# This script automates the iOS build process for different environments

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="AndCo School Transport"
WORKSPACE="ios/Runner.xcworkspace"
SCHEME="Runner"
OUTPUT_DIR="build/ios"

# Functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  $PROJECT_NAME - iOS Build${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "iOS builds can only be performed on macOS"
        exit 1
    fi
    
    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    
    # Check Xcode
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode is not installed or command line tools are not available"
        exit 1
    fi
    
    # Check CocoaPods
    if ! command -v pod &> /dev/null; then
        print_error "CocoaPods is not installed. Install with: sudo gem install cocoapods"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Clean project
clean_project() {
    print_info "Cleaning project..."
    flutter clean
    flutter pub get
    
    # Clean iOS
    cd ios
    rm -rf Pods
    rm -rf .symlinks
    rm -rf Flutter/Flutter.framework
    rm -rf Flutter/Flutter.podspec
    pod install --repo-update
    cd ..
    
    print_success "Project cleaned"
}

# Update CocoaPods
update_pods() {
    print_info "Updating CocoaPods..."
    cd ios
    pod install --repo-update
    cd ..
    print_success "CocoaPods updated"
}

# Run tests
run_tests() {
    print_info "Running tests..."
    flutter test
    
    # Run iOS unit tests
    print_info "Running iOS unit tests..."
    cd ios
    xcodebuild test -workspace Runner.xcworkspace -scheme Runner -destination 'platform=iOS Simulator,name=iPhone 14,OS=latest'
    cd ..
    
    print_success "Tests passed"
}

# Build iOS
build_ios() {
    local build_type=$1
    local environment=$2
    
    print_info "Building iOS $build_type for $environment environment..."
    
    # Create output directory
    mkdir -p $OUTPUT_DIR
    
    case $build_type in
        "debug")
            flutter build ios --debug --flavor $environment
            ;;
        "release")
            flutter build ios --release --flavor $environment
            ;;
        "archive")
            # Build archive for App Store
            flutter build ios --release --flavor $environment
            
            print_info "Creating Xcode archive..."
            cd ios
            xcodebuild archive \
                -workspace Runner.xcworkspace \
                -scheme Runner \
                -configuration Release-$environment \
                -archivePath "../$OUTPUT_DIR/AndCo-$environment.xcarchive" \
                -allowProvisioningUpdates
            cd ..
            
            print_success "Archive created: $OUTPUT_DIR/AndCo-$environment.xcarchive"
            ;;
        "ipa")
            # Build IPA for distribution
            flutter build ios --release --flavor $environment
            
            print_info "Creating Xcode archive..."
            cd ios
            xcodebuild archive \
                -workspace Runner.xcworkspace \
                -scheme Runner \
                -configuration Release-$environment \
                -archivePath "../$OUTPUT_DIR/AndCo-$environment.xcarchive" \
                -allowProvisioningUpdates
            
            print_info "Exporting IPA..."
            xcodebuild -exportArchive \
                -archivePath "../$OUTPUT_DIR/AndCo-$environment.xcarchive" \
                -exportPath "../$OUTPUT_DIR" \
                -exportOptionsPlist "ExportOptions-$environment.plist"
            cd ..
            
            print_success "IPA created in: $OUTPUT_DIR"
            ;;
        *)
            print_error "Invalid build type: $build_type"
            exit 1
            ;;
    esac
}

# Create export options plist
create_export_options() {
    local environment=$1
    local export_method=$2
    
    cat > ios/ExportOptions-$environment.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$export_method</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <true/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <true/>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF
}

# Generate build info
generate_build_info() {
    local environment=$1
    local build_type=$2
    
    cat > $OUTPUT_DIR/build-info-$environment-$build_type.txt << EOF
Build Information
=================
Project: $PROJECT_NAME
Environment: $environment
Build Type: $build_type
Build Date: $(date)
Flutter Version: $(flutter --version | head -n 1)
Xcode Version: $(xcodebuild -version | head -n 1)
Git Commit: $(git rev-parse HEAD 2>/dev/null || echo "Not a git repository")
Git Branch: $(git branch --show-current 2>/dev/null || echo "Not a git repository")

Build Configuration:
- iOS Deployment Target: 12.0
- Supported Devices: iPhone, iPad
- Swift Version: 5.0
- Bitcode: Enabled (Release only)

Features Enabled:
- Firebase Integration
- Google Maps
- Biometric Authentication (Face ID/Touch ID)
- Push Notifications
- Background Location
- Deep Linking
EOF
}

# Upload to TestFlight
upload_testflight() {
    local environment=$1
    
    print_info "Uploading to TestFlight..."
    
    # Check if IPA exists
    local ipa_path="$OUTPUT_DIR/AndCo-$environment.ipa"
    if [ ! -f "$ipa_path" ]; then
        print_error "IPA file not found: $ipa_path"
        exit 1
    fi
    
    # Upload using altool
    xcrun altool --upload-app \
        --type ios \
        --file "$ipa_path" \
        --username "$APPLE_ID" \
        --password "$APP_SPECIFIC_PASSWORD"
    
    print_success "Upload to TestFlight completed"
}

# Main script
main() {
    print_header
    
    # Parse arguments
    BUILD_TYPE=${1:-"debug"}
    ENVIRONMENT=${2:-"dev"}
    SKIP_TESTS=${3:-"false"}
    UPLOAD_TESTFLIGHT=${4:-"false"}
    
    print_info "Build configuration:"
    print_info "  Build Type: $BUILD_TYPE"
    print_info "  Environment: $ENVIRONMENT"
    print_info "  Skip Tests: $SKIP_TESTS"
    print_info "  Upload TestFlight: $UPLOAD_TESTFLIGHT"
    echo
    
    # Validate arguments
    if [[ ! "$BUILD_TYPE" =~ ^(debug|release|archive|ipa)$ ]]; then
        print_error "Invalid build type. Use: debug, release, archive, or ipa"
        exit 1
    fi
    
    if [[ ! "$ENVIRONMENT" =~ ^(dev|prod)$ ]]; then
        print_error "Invalid environment. Use: dev or prod"
        exit 1
    fi
    
    # Execute build steps
    check_prerequisites
    clean_project
    update_pods
    
    if [ "$SKIP_TESTS" != "true" ]; then
        run_tests
    else
        print_warning "Skipping tests"
    fi
    
    # Create export options for IPA builds
    if [ "$BUILD_TYPE" == "ipa" ]; then
        if [ "$ENVIRONMENT" == "prod" ]; then
            create_export_options $ENVIRONMENT "app-store"
        else
            create_export_options $ENVIRONMENT "development"
        fi
    fi
    
    build_ios $BUILD_TYPE $ENVIRONMENT
    generate_build_info $ENVIRONMENT $BUILD_TYPE
    
    # Upload to TestFlight if requested
    if [ "$UPLOAD_TESTFLIGHT" == "true" ] && [ "$BUILD_TYPE" == "ipa" ]; then
        upload_testflight $ENVIRONMENT
    fi
    
    print_success "iOS build completed successfully!"
    print_info "Output files are in $OUTPUT_DIR/"
    
    # Show build artifacts
    echo
    print_info "Build artifacts:"
    ls -lah $OUTPUT_DIR/ 2>/dev/null || true
}

# Help function
show_help() {
    echo "Usage: $0 [BUILD_TYPE] [ENVIRONMENT] [SKIP_TESTS] [UPLOAD_TESTFLIGHT]"
    echo
    echo "BUILD_TYPE:"
    echo "  debug    - Debug build for simulator/device testing"
    echo "  release  - Release build for device testing"
    echo "  archive  - Create Xcode archive"
    echo "  ipa      - Create IPA for distribution"
    echo
    echo "ENVIRONMENT:"
    echo "  dev      - Development environment"
    echo "  prod     - Production environment"
    echo
    echo "SKIP_TESTS:"
    echo "  true     - Skip running tests"
    echo "  false    - Run tests (default)"
    echo
    echo "UPLOAD_TESTFLIGHT:"
    echo "  true     - Upload IPA to TestFlight"
    echo "  false    - Don't upload (default)"
    echo
    echo "Environment Variables:"
    echo "  APPLE_ID              - Apple ID for TestFlight upload"
    echo "  APP_SPECIFIC_PASSWORD - App-specific password for TestFlight"
    echo
    echo "Examples:"
    echo "  $0                           # Debug build, dev environment"
    echo "  $0 release prod              # Release build, prod environment"
    echo "  $0 ipa prod false true       # IPA build, prod environment, upload to TestFlight"
}

# Check for help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Run main function
main "$@"
