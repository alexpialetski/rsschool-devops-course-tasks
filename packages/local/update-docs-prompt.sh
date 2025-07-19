#!/bin/bash

# Check if the readme-checkpoint tag exists
if ! git rev-parse --verify readme-checkpoint >/dev/null 2>&1; then
  echo "Error: 'readme-checkpoint' tag not found."
  echo "Please create a tag marking the last documentation checkpoint."
  echo "Example: git tag readme-checkpoint <commit-hash>"
  exit 1
fi

# Get the hash of the readme-checkpoint tag
checkpoint_hash=$(git rev-parse readme-checkpoint)
echo "Found readme-checkpoint tag at commit: $(git log -1 --format='%h %s' $checkpoint_hash)"

# Get all commits since the checkpoint with their details
echo "Collecting commits since readme-checkpoint..."
commits=$(git log --pretty=format:"%H" $checkpoint_hash..HEAD)
commit_count=$(echo "$commits" | wc -l | tr -d ' ')
echo "Found $commit_count commits to analyze"

# Generate the prompt
echo -e "\n\n========= GENERATED DOCUMENTATION UPDATE PROMPT =========\n"

cat << EOF
I need to update the documentation in my repository. Here's what has changed since the last documentation checkpoint:

## Commits and Changed Files

EOF

# For each commit, show details and changed files with their status
for commit in $commits; do
  commit_date=$(git show -s --format="%cd" --date=short $commit)
  commit_msg=$(git show -s --format="%s" $commit)
  commit_author=$(git show -s --format="%an" $commit)

  echo "- $commit_date: $commit_msg (by $commit_author)"

  # Get files with their status (A: added, M: modified, D: deleted, R: renamed)
  git show --name-status --format= $commit | while read status file1 file2; do
    if [ -n "$status" ] && [ -n "$file1" ]; then
      case $status in
        A)
          echo "  - $file1 (added)"
          ;;
        M)
          echo "  - $file1 (modified)"
          ;;
        D)
          echo "  - $file1 (deleted)"
          ;;
        R*)
          echo "  - $file2 (renamed from $file1)"
          ;;
        *)
          echo "  - $file1 ($status)"
          ;;
      esac
    fi
  done
done

# Mention NX projects
echo -e "\n## NX Projects"
echo "You can use the NX Console plugin to view affected projects and their dependencies."
echo "To get information about NX projects, use the nx_workspace and nx_project_details tools."

# Workflows and actions section
echo -e "\n## GitHub Workflows and Actions"
echo "Look for changes in .github/workflows/ and .github/actions/ directories above to identify CI/CD updates."

# Final instructions
cat << EOF

Please help me update the documentation files with the following guidelines:
1. Keep documentation concise - humans get tired of reading long texts.
2. Avoid repeating information between docs - use references to other docs where appropriate.
3. Avoid getting too detailed about file structures or resource names that change frequently.
4. Focus on high-level concepts, workflows, and integration patterns.
5. Include clear examples where relevant, but keep them minimal.
6. Each NX project should have a README file that explains its purpose and usage.

After these updates are complete, I'll mark a new "readme-checkpoint" tag.
EOF

echo -e "\n========= END OF PROMPT =========\n"

echo "Script completed. Copy the prompt above to use with your AI assistant."
echo "When documentation is updated, create a new checkpoint with:"
echo "  git tag -f readme-checkpoint HEAD"
