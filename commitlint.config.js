module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'scope-enum': [2, 'always', ['multi-review', 'jira-cli', 'repo', 'pr-desc-review', 'claude-cleanup', 'git-absorb', 'skill-cso-review', 'logseq', 'mac-notifications', 'review-pr-comments']],
    'scope-empty': [0],
  },
};
