#!/bin/bash

# AndCo School Transport - Release Management Script
# This script automates version management and release preparation

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="AndCo School Transport"
PUBSPEC_FILE="pubspec.yaml"
CHANGELOG_FILE="CHANGELOG.md"
VERSION_FILE="version.txt"

# Functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  $PROJECT_NAME - Release Management${NC}"
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

# Get current version from pubspec.yaml
get_current_version() {
    grep "^version:" $PUBSPEC_FILE | sed 's/version: //' | tr -d ' '
}

# Parse version components
parse_version() {
    local version=$1
    echo $version | sed 's/+.*//' # Remove build number
}

# Get build number
get_build_number() {
    local version=$1
    echo $version | sed 's/.*+//' # Extract build number
}

# Increment version
increment_version() {
    local version=$1
    local type=$2
    
    local major=$(echo $version | cut -d. -f1)
    local minor=$(echo $version | cut -d. -f2)
    local patch=$(echo $version | cut -d. -f3)
    
    case $type in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch")
            patch=$((patch + 1))
            ;;
        *)
            print_error "Invalid version type: $type"
            exit 1
            ;;
    esac
    
    echo "$major.$minor.$patch"
}

# Update version in pubspec.yaml
update_pubspec_version() {
    local new_version=$1
    local build_number=$2
    
    sed -i.bak "s/^version:.*/version: $new_version+$build_number/" $PUBSPEC_FILE
    rm $PUBSPEC_FILE.bak
    
    print_success "Updated version in $PUBSPEC_FILE to $new_version+$build_number"
}

# Generate changelog entry
generate_changelog_entry() {
    local version=$1
    local date=$(date +"%Y-%m-%d")
    
    # Get commits since last tag
    local last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    local commits=""
    
    if [ -n "$last_tag" ]; then
        commits=$(git log --oneline --pretty=format:"- %s" $last_tag..HEAD)
    else
        commits=$(git log --oneline --pretty=format:"- %s")
    fi
    
    # Create changelog entry
    local changelog_entry="## [$version] - $date

### Added
### Changed
### Fixed
### Removed

### Commits
$commits

"
    
    # Prepend to changelog
    if [ -f "$CHANGELOG_FILE" ]; then
        echo "$changelog_entry$(cat $CHANGELOG_FILE)" > $CHANGELOG_FILE
    else
        echo "$changelog_entry" > $CHANGELOG_FILE
    fi
    
    print_success "Generated changelog entry for version $version"
}

# Create release notes
create_release_notes() {
    local version=$1
    local output_file="release_notes_$version.md"
    
    cat > $output_file << EOF
# AndCo School Transport v$version Release Notes

## What's New

### Features
- [List new features here]

### Improvements
- [List improvements here]

### Bug Fixes
- [List bug fixes here]

## Technical Details

### Build Information
- **Version**: $version
- **Build Date**: $(date)
- **Flutter Version**: $(flutter --version | head -n 1)
- **Git Commit**: $(git rev-parse HEAD)

### Supported Platforms
- **Android**: API 23+ (Android 6.0+)
- **iOS**: iOS 12.0+

### Dependencies
- Firebase SDK
- Google Maps SDK
- Stripe SDK
- Local Authentication (Biometrics)

## Installation

### Android
1. Download the APK from the release page
2. Enable "Install from unknown sources" in device settings
3. Install the APK

### iOS
1. Download from TestFlight or App Store
2. Follow installation instructions

## Known Issues
- [List any known issues]

## Support
For support, please contact: support@andco.app

---
**Full Changelog**: [View on GitHub](https://github.com/andco/school-transport/compare/v$version)
EOF
    
    print_success "Created release notes: $output_file"
}

# Create git tag
create_git_tag() {
    local version=$1
    local tag_name="v$version"
    
    # Check if tag already exists
    if git tag -l | grep -q "^$tag_name$"; then
        print_warning "Tag $tag_name already exists"
        return
    fi
    
    # Create annotated tag
    git tag -a $tag_name -m "Release version $version"
    print_success "Created git tag: $tag_name"
}

# Validate release readiness
validate_release() {
    print_info "Validating release readiness..."
    
    # Check if working directory is clean
    if [ -n "$(git status --porcelain)" ]; then
        print_error "Working directory is not clean. Please commit or stash changes."
        exit 1
    fi
    
    # Check if on main branch
    local current_branch=$(git branch --show-current)
    if [ "$current_branch" != "main" ] && [ "$current_branch" != "master" ]; then
        print_warning "Not on main/master branch. Current branch: $current_branch"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Check if tests pass
    print_info "Running tests..."
    flutter test
    
    print_success "Release validation passed"
}

# Build release artifacts
build_release_artifacts() {
    local version=$1
    
    print_info "Building release artifacts..."
    
    # Create build directory
    mkdir -p "releases/v$version"
    
    # Build Android
    print_info "Building Android release..."
    ./scripts/build_android.sh release prod
    cp build/android/*.apk "releases/v$version/"
    cp build/android/*.aab "releases/v$version/"
    
    # Build iOS (if on macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_info "Building iOS release..."
        ./scripts/build_ios.sh ipa prod
        cp build/ios/*.ipa "releases/v$version/" 2>/dev/null || true
    else
        print_warning "Skipping iOS build (not on macOS)"
    fi
    
    print_success "Release artifacts built in releases/v$version/"
}

# Main release function
create_release() {
    local version_type=$1
    local current_version=$(get_current_version)
    local current_version_number=$(parse_version $current_version)
    local current_build_number=$(get_build_number $current_version)
    
    print_info "Current version: $current_version"
    
    # Calculate new version
    local new_version_number=$(increment_version $current_version_number $version_type)
    local new_build_number=$((current_build_number + 1))
    local new_version="$new_version_number+$new_build_number"
    
    print_info "New version: $new_version"
    
    # Confirm release
    read -p "Create release v$new_version_number? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Release cancelled"
        exit 0
    fi
    
    # Validate release readiness
    validate_release
    
    # Update version
    update_pubspec_version $new_version_number $new_build_number
    
    # Generate changelog
    generate_changelog_entry $new_version_number
    
    # Create release notes
    create_release_notes $new_version_number
    
    # Commit changes
    git add $PUBSPEC_FILE $CHANGELOG_FILE
    git commit -m "chore: bump version to $new_version_number"
    
    # Create tag
    create_git_tag $new_version_number
    
    # Build artifacts
    build_release_artifacts $new_version_number
    
    print_success "Release v$new_version_number created successfully!"
    print_info "Next steps:"
    print_info "  1. Review and edit release notes: release_notes_$new_version_number.md"
    print_info "  2. Push changes: git push origin main --tags"
    print_info "  3. Create GitHub release with artifacts in releases/v$new_version_number/"
    print_info "  4. Deploy to app stores using CI/CD pipeline"
}

# Show current version
show_version() {
    local current_version=$(get_current_version)
    print_info "Current version: $current_version"
    
    # Show git tags
    print_info "Recent tags:"
    git tag -l --sort=-version:refname | head -5
}

# Main script
main() {
    print_header
    
    local command=${1:-"help"}
    
    case $command in
        "major"|"minor"|"patch")
            create_release $command
            ;;
        "version")
            show_version
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Invalid command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Help function
show_help() {
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  major    - Create major release (x.0.0)"
    echo "  minor    - Create minor release (x.y.0)"
    echo "  patch    - Create patch release (x.y.z)"
    echo "  version  - Show current version"
    echo "  help     - Show this help message"
    echo
    echo "Examples:"
    echo "  $0 patch   # Create patch release (1.0.0 -> 1.0.1)"
    echo "  $0 minor   # Create minor release (1.0.1 -> 1.1.0)"
    echo "  $0 major   # Create major release (1.1.0 -> 2.0.0)"
    echo
    echo "The script will:"
    echo "  1. Validate release readiness"
    echo "  2. Update version in pubspec.yaml"
    echo "  3. Generate changelog entry"
    echo "  4. Create release notes"
    echo "  5. Commit changes and create git tag"
    echo "  6. Build release artifacts"
}

# Run main function
main "$@"
