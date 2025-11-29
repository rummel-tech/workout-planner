#!/bin/sh
# Script to copy frontend UI modules into frontend/legacy_ui for consolidation.
# Run from repository root: sh scripts/consolidate_frontend.sh [--dry-run]

DRY_RUN=0
if [ "$1" = "--dry-run" ]; then
  DRY_RUN=1
fi

SRC_ROOT="."
DST_ROOT="frontend/legacy_ui"

MODULES="ai_insights_ui app_scaffold app_shell app_shell_with_bottom_nav app_theme goals_ui home_dashboard_integration home_dashboard_ui morning_routine_ui navigation_system notification_system onboarding_flow readiness_ui settings_profile_ui today_view_ui todays_workout_ui weekly_plan_ui flutter_app_starter ui_theme_pack lib"

mkdir -p "$DST_ROOT"

for m in $MODULES; do
  if [ -d "$SRC_ROOT/$m" ]; then
    if [ $DRY_RUN -eq 1 ]; then
      echo "Would copy $SRC_ROOT/$m -> $DST_ROOT/$m"
    else
      echo "Copying $SRC_ROOT/$m -> $DST_ROOT/$m"
      # Prefer rsync when available, fall back to POSIX cp
      if command -v rsync >/dev/null 2>&1; then
        rsync -a --delete --exclude='.git' "$SRC_ROOT/$m" "$DST_ROOT/"
      else
        # Ensure destination folder exists and copy contents (preserve attributes)
        mkdir -p "$DST_ROOT/$m"
        # Use a safe copy: copy contents of source into destination
        cp -a "$SRC_ROOT/$m/." "$DST_ROOT/$m/" 2>/dev/null || {
          # Fallback for older shells without cp -a support
          find "$SRC_ROOT/$m" -mindepth 1 -maxdepth 1 -exec cp -R {} "$DST_ROOT/$m/" \;
        }
      fi
    fi
  else
    echo "Skipping $m (not found)"
  fi
done

echo "Done. Review files under $DST_ROOT. After verification, you can remove original folders or update imports to point at the consolidated location."
