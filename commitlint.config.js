module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'scope-enum': [2, 'always', ['multi-review', 'jira-cli', 'repo', 'pr-desc-review', 'claude-cleanup']],
    'scope-empty': [0],
  },
};
