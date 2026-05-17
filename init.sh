#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  Android Starter — CI/CD scaffold for low-end laptops
#  Usage:   ./init.sh MyApp
#  Requires: git, gh (GitHub CLI), curl
# ============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { printf "${GREEN}✓${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}⚠${NC} %s\n" "$1"; }
err()  { printf "${RED}✘${NC} %s\n" "$1"; exit 1; }
info() { printf "${CYAN}•${NC} %s\n" "$1"; }

# ---- Parse args -------------------------------------------------
APP_NAME="${1:-}"
if [[ -z "$APP_NAME" ]]; then
  echo "Usage: $0 <AppName>"
  exit 1
fi

PKG="com.example.$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/-/_/g')"
DIR="$PWD/$APP_NAME"
APP_NAME_SAFE="$(echo "$APP_NAME" | sed 's/-/_/g')"
JAVA_VER="${JAVA_VERSION:-17}"
API="${TARGET_API:-35}"
MIN_SDK="${MIN_SDK:-24}"
GRADLE_VER="${GRADLE_VERSION:-8.11}"
AGP_VER="${AGP_VERSION:-8.7.3}"
KOTLIN_VER="${KOTLIN_VERSION:-2.1.0}"
COMPILE_SDK="${API}"
TARGET_SDK="${API}"

# ---- Dependency check -------------------------------------------
command -v git  >/dev/null 2>&1 || err "git is required"
command -v curl >/dev/null 2>&1 || err "curl is required"
if ! command -v gh >/dev/null 2>&1; then
  warn "gh (GitHub CLI) not found — skipping repo creation"
  NO_GH=1
else
  NO_GH=0
fi

# ---- Create project ---------------------------------------------
if [[ -d "$DIR" ]]; then
  err "Directory '$DIR' already exists"
fi

info "Creating project: $APP_NAME ($PKG)"
mkdir -p "$DIR/app/src/main/java/${PKG//.//}"
mkdir -p "$DIR/app/src/main/res/values"
mkdir -p "$DIR/app/src/main/res/mipmap-hdpi"
mkdir -p "$DIR/gradle/wrapper"
mkdir -p "$DIR/.github/workflows"

# --- gradle-wrapper.properties ---
cat > "$DIR/gradle/wrapper/gradle-wrapper.properties" << EOF
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-${GRADLE_VER}-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

# --- gradlew (download official scripts) ---
curl -sL "https://raw.githubusercontent.com/gradle/gradle/master/gradlew" \
  -o "$DIR/gradlew" && chmod +x "$DIR/gradlew"
curl -sL "https://raw.githubusercontent.com/gradle/gradle/master/gradlew.bat" \
  -o "$DIR/gradlew.bat"

# --- settings.gradle.kts ---
cat > "$DIR/settings.gradle.kts" << EOF
pluginManagement {
  repositories {
    google()
    mavenCentral()
    gradlePluginPortal()
  }
}

dependencyResolutionManagement {
  repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
  repositories {
    google()
    mavenCentral()
  }
}

rootProject.name = "$APP_NAME"
include(":app")
EOF

# --- root build.gradle.kts ---
cat > "$DIR/build.gradle.kts" << EOF
plugins {
  id("com.android.application") version "$AGP_VER" apply false
  id("org.jetbrains.kotlin.android") version "$KOTLIN_VER" apply false
}
EOF

# --- gradle.properties ---
cat > "$DIR/gradle.properties" << EOF
org.gradle.jvmargs=-Xmx2g -XX:MaxMetaspaceSize=512m
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configureondemand=true
android.useAndroidX=true
android.nonTransitiveRClass=true
kotlin.code.style=official
EOF

# --- app/build.gradle.kts ---
cat > "$DIR/app/build.gradle.kts" << EOF
plugins {
  id("com.android.application")
  id("org.jetbrains.kotlin.android")
}

android {
  namespace = "$PKG"
  compileSdk = $COMPILE_SDK

  defaultConfig {
    applicationId = "$PKG"
    minSdk = $MIN_SDK
    targetSdk = $TARGET_SDK
    versionCode = 1
    versionName = "1.0"
    testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
  }

  buildTypes {
    release {
      isMinifyEnabled = true
      proguardFiles(
        getDefaultProguardFile("proguard-android-optimize.txt"),
        "proguard-rules.pro"
      )
    }
    debug {
      isDebuggable = true
    }
  }

  compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
  }

  kotlinOptions {
    jvmTarget = "17"
  }

  buildFeatures {
    viewBinding = true
  }
}

dependencies {
  implementation("androidx.core:core-ktx:1.15.0")
  implementation("androidx.appcompat:appcompat:1.7.0")
  implementation("androidx.activity:activity-ktx:1.9.3")
  implementation("com.google.android.material:material:1.12.0")
  implementation("androidx.constraintlayout:constraintlayout:2.2.1")

  testImplementation("junit:junit:4.13.2")
  androidTestImplementation("androidx.test.ext:junit:1.2.1")
  androidTestImplementation("androidx.test.espresso:espresso-core:3.6.1")
}
EOF

# --- AndroidManifest.xml ---
cat > "$DIR/app/src/main/AndroidManifest.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

  <application
    android:allowBackup="true"
    android:label="@string/app_name"
    android:supportsRtl="true"
    android:theme="@style/Theme.$APP_NAME_SAFE">

    <activity
      android:name=".MainActivity"
      android:exported="true">
      <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
      </intent-filter>
    </activity>
  </application>

</manifest>
EOF

# --- layout/activity_main.xml ---
mkdir -p "$DIR/app/src/main/res/layout"
cat > "$DIR/app/src/main/res/layout/activity_main.xml" << 'LAYOUT_EOF'
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout
  xmlns:android="http://schemas.android.com/apk/res/android"
  xmlns:app="http://schemas.android.com/apk/res-auto"
  android:layout_width="match_parent"
  android:layout_height="match_parent"
  android:padding="16dp">

  <TextView
    android:id="@+id/title"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:text="@string/app_name"
    android:textAppearance="@style/TextAppearance.Material3.HeadlineMedium"
    app:layout_constraintBottom_toBottomOf="parent"
    app:layout_constraintEnd_toEndOf="parent"
    app:layout_constraintStart_toStartOf="parent"
    app:layout_constraintTop_toTopOf="parent" />
</androidx.constraintlayout.widget.ConstraintLayout>
LAYOUT_EOF

# --- MainActivity.kt ---
cat > "$DIR/app/src/main/java/${PKG//.//}/MainActivity.kt" << EOF
package $PKG

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import ${PKG}.databinding.ActivityMainBinding

class MainActivity : AppCompatActivity() {
  private lateinit var binding: ActivityMainBinding

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    binding = ActivityMainBinding.inflate(layoutInflater)
    setContentView(binding.root)
  }
}
EOF

# --- strings.xml ---
cat > "$DIR/app/src/main/res/values/strings.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<resources>
  <string name="app_name">$APP_NAME</string>
</resources>
EOF

# --- themes.xml ---
cat > "$DIR/app/src/main/res/values/themes.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<resources>
  <style name="Theme.$APP_NAME_SAFE" parent="Theme.Material3.DayNight.NoActionBar">
    <item name="colorPrimary">@*android:color/system_primary_light</item>
  </style>
</resources>
EOF

# --- proguard-rules.pro ---
touch "$DIR/app/proguard-rules.pro"

log "Project scaffold created"

# ---- Download Gradle wrapper jar ---------------------------------
info "Downloading Gradle wrapper JAR…"
curl -sL "https://raw.githubusercontent.com/gradle/gradle/master/gradle/wrapper/gradle-wrapper.jar" \
  -o "$DIR/gradle/wrapper/gradle-wrapper.jar" || {
  warn "Could not download wrapper jar — create it manually:"
  warn "  cd $DIR && gradle wrapper"
  touch "$DIR/gradle/wrapper/gradle-wrapper.jar"
}
log "Gradle wrapper ready"

# ---- Copy CI templates -------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES="$SCRIPT_DIR/templates"

if [[ -d "$TEMPLATES" ]]; then
  cp "$TEMPLATES/android.yml"   "$DIR/.github/workflows/"
  cp "$TEMPLATES/emulator.yml"  "$DIR/.github/workflows/"
  cp "$TEMPLATES/release.yml"   "$DIR/.github/workflows/"
  cp "$TEMPLATES/gitignore"     "$DIR/.gitignore"
  log "CI workflows installed"
else
  warn "Templates directory not found at $TEMPLATES — skipping CI setup"
fi

# ---- git init ----------------------------------------------------
cd "$DIR"
git init
git branch -m main
git add -A
git commit -m "Initial commit: $APP_NAME"
log "Git repository initialized"

# ---- GitHub repo -------------------------------------------------
if [[ "$NO_GH" -eq 0 ]]; then
  info "Creating GitHub repository: $APP_NAME"
  if gh repo create "$APP_NAME" --private --source=. --remote=origin --push 2>&1; then
    log "Repository created and pushed to GitHub"
  else
    warn "gh repo create failed — push manually later"
  fi
else
  warn "Skipping GitHub repo — install gh CLI and run:"
  warn "  cd $DIR && gh repo create $APP_NAME --private --source=. --remote=origin --push"
fi

# ---- Summary -----------------------------------------------------
echo ""
echo "============================================"
echo "  $APP_NAME  —  ready!"
echo "============================================"
echo ""
echo "  Location:  $DIR"
echo "  Package:   $PKG"
echo ""
echo "  Workflows installed:"
echo "    • Android CI       → debug APK + unit tests"
echo "    • Emulator Tests   → instrumentation tests"
echo "    • Release Build    → APK + AAB + signing"
echo ""
echo "  Next steps:"
echo "    cd $DIR"
echo "    code .              # or any editor"
echo "    git push            # triggers CI"
echo ""
echo "  Download APK when CI finishes from:"
echo "    GitHub → Actions → Android CI → artifact"
echo ""
