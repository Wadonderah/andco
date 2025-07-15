#!/bin/bash

# AndCo School Transport - Android Build Script
# This script automates the Android build process for different environments

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="AndCo School Transport"
FLUTTER_VERSION="3.16.0"
MIN_FLUTTER_VERSION="3.10.0"

# Functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  $PROJECT_NAME - Android Build${NC}"
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
    
    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    
    # Check Flutter version
    CURRENT_FLUTTER_VERSION=$(flutter --version | grep -o 'Flutter [0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
    print_info "Flutter version: $CURRENT_FLUTTER_VERSION"
    
    # Check Android SDK
    if [ -z "$ANDROID_HOME" ]; then
        print_error "ANDROID_HOME environment variable is not set"
        exit 1
    fi
    
    # Check Java
    if ! command -v java &> /dev/null; then
        print_error "Java is not installed or not in PATH"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Clean project
clean_project() {
    print_info "Cleaning project..."
    flutter clean
    flutter pub get
    cd android && ./gradlew clean && cd ..
    print_success "Project cleaned"
}

# Run tests
run_tests() {
    print_info "Running tests..."
    flutter test
    print_success "Tests passed"
}

# Build function
build_android() {
    local build_type=$1
    local flavor=$2
    local output_dir="build/android"
    
    print_info "Building Android $build_type for $flavor flavor..."
    
    # Create output directory
    mkdir -p $output_dir
    
    case $build_type in
        "debug")
            flutter build apk --debug --flavor $flavor
            cp build/app/outputs/flutter-apk/app-$flavor-debug.apk $output_dir/andco-$flavor-debug.apk
            ;;
        "release")
            # Check if keystore exists
            if [ ! -f "android/key.properties" ]; then
                print_error "Release keystore configuration not found. Please create android/key.properties"
                print_info "Use android/key.properties.template as a reference"
                exit 1
            fi
            
            flutter build apk --release --flavor $flavor
            cp build/app/outputs/flutter-apk/app-$flavor-release.apk $output_dir/andco-$flavor-release.apk
            ;;
        "bundle")
            # Check if keystore exists
            if [ ! -f "android/key.properties" ]; then
                print_error "Release keystore configuration not found. Please create android/key.properties"
                exit 1
            fi
            
            flutter build appbundle --release --flavor $flavor
            cp build/app/outputs/bundle/${flavor}Release/app-$flavor-release.aab $output_dir/andco-$flavor-release.aab
            ;;
        *)
            print_error "Invalid build type: $build_type"
            exit 1
            ;;
    esac
    
    print_success "Build completed: $output_dir/andco-$flavor-$build_type.*"
}

# Generate build info
generate_build_info() {
    local flavor=$1
    local build_type=$2
    local output_dir="build/android"
    
    cat > $output_dir/build-info-$flavor-$build_type.txt << EOF
Build Information
=================
Project: $PROJECT_NAME
Flavor: $flavor
Build Type: $build_type
Build Date: $(date)
Flutter Version: $(flutter --version | head -n 1)
Git Commit: $(git rev-parse HEAD 2>/dev/null || echo "Not a git repository")
Git Branch: $(git branch --show-current 2>/dev/null || echo "Not a git repository")

Build Configuration:
- Target SDK: 34
- Min SDK: 23
- Compile SDK: 34
- Build Tools: Latest

Features Enabled:
- Firebase Integration
- Google Maps
- Biometric Authentication
- Push Notifications
- Secure Storage
- ProGuard Obfuscation (Release only)
EOF
}

# Main script
main() {
    print_header
    
    # Parse arguments
    BUILD_TYPE=${1:-"debug"}
    FLAVOR=${2:-"dev"}
    SKIP_TESTS=${3:-"false"}
    
    print_info "Build configuration:"
    print_info "  Build Type: $BUILD_TYPE"
    print_info "  Flavor: $FLAVOR"
    print_info "  Skip Tests: $SKIP_TESTS"
    echo
    
    # Validate arguments
    if [[ ! "$BUILD_TYPE" =~ ^(debug|release|bundle)$ ]]; then
        print_error "Invalid build type. Use: debug, release, or bundle"
        exit 1
    fi
    
    if [[ ! "$FLAVOR" =~ ^(dev|prod)$ ]]; then
        print_error "Invalid flavor. Use: dev or prod"
        exit 1
    fi
    
    # Execute build steps
    check_prerequisites
    clean_project
    
    if [ "$SKIP_TESTS" != "true" ]; then
        run_tests
    else
        print_warning "Skipping tests"
    fi
    
    build_android $BUILD_TYPE $FLAVOR
    generate_build_info $FLAVOR $BUILD_TYPE
    
    print_success "Android build completed successfully!"
    print_info "Output files are in build/android/"
    
    # Show file sizes
    echo
    print_info "Build artifacts:"
    ls -lh build/android/andco-$FLAVOR-$BUILD_TYPE.* 2>/dev/null || true
}

# Help function
show_help() {
    echo "Usage: $0 [BUILD_TYPE] [FLAVOR] [SKIP_TESTS]"
    echo
    echo "BUILD_TYPE:"
    echo "  debug    - Debug build with debugging enabled"
    echo "  release  - Release build with optimizations"
    echo "  bundle   - App Bundle for Google Play Store"
    echo
    echo "FLAVOR:"
    echo "  dev      - Development environment"
    echo "  prod     - Production environment"
    echo
    echo "SKIP_TESTS:"
    echo "  true     - Skip running tests"
    echo "  false    - Run tests (default)"
    echo
    echo "Examples:"
    echo "  $0                           # Debug build, dev flavor"
    echo "  $0 release prod              # Release build, prod flavor"
    echo "  $0 bundle prod true          # Bundle build, prod flavor, skip tests"
}

# Check for help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Run main function
main "$@"
