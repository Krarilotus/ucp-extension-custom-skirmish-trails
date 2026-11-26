// File paths panel: shows the trail's file settings (trail settings file, default csv file,
// csv files per language) and clears them.

const filePathsText = {};
const filePathsCleared = new Set();
let filePathsValues = {};

SANDBOX_FUNCTIONS.getConfig = () =>
  Object.fromEntries([...filePathsCleared].map((key) => [key, '']));

function filePathLabel(key) {
  if (key === 'settings.path') return filePathsText.settings;
  if (key === 'csv.path') return filePathsText.csv;
  const language = key.replace(/^csv\.languages\./, '');
  return `${filePathsText.csv} (${language.charAt(0).toUpperCase()}${language.slice(1)})`;
}

function filePathKeys() {
  return Object.keys(filePathsValues)
    .filter((key) => key === 'settings.path' || key === 'csv.path' || key.startsWith('csv.languages.'))
    .sort((a, b) => {
      const order = (key) => (key === 'settings.path' ? 0 : key === 'csv.path' ? 1 : 2);
      return order(a) - order(b) || a.localeCompare(b);
    });
}

function filePathCurrent(key) {
  return filePathsCleared.has(key) ? '' : `${filePathsValues[key] ?? ''}`;
}

function renderFilePaths() {
  const table = document.getElementById('paths');
  table.textContent = '';
  const keys = filePathKeys().filter((key) => filePathCurrent(key) !== '' || filePathsCleared.has(key));
  if (keys.length === 0) {
    const row = table.insertRow();
    row.insertCell().textContent = filePathsText.none;
  }
  for (const key of keys) {
    const row = table.insertRow();
    row.insertCell().textContent = filePathLabel(key);
    const value = row.insertCell();
    value.textContent = filePathCurrent(key) || filePathsText.cleared;
    value.className = 'path';
    const action = row.insertCell();
    if (!filePathsCleared.has(key)) {
      const button = document.createElement('button');
      button.type = 'button';
      button.textContent = filePathsText.clear;
      button.onclick = () => {
        filePathsCleared.add(key);
        renderFilePaths();
      };
      action.appendChild(button);
    }
  }

  const settingsSet = filePathCurrent('settings.path') !== '';
  document.getElementById('notice').textContent = settingsSet ? filePathsText.notice : '';
  document.getElementById('status').textContent = filePathsCleared.size
    ? filePathsText.status.replace('{count}', filePathsCleared.size)
    : '';
}

addEventListener('INIT_DONE', async () => {
  for (const id of ['settings', 'csv', 'none', 'cleared', 'clear', 'notice', 'status']) {
    filePathsText[id] = (await HOST_FUNCTIONS.getLocalizedString(`menu_paths_${id}`)) ?? id;
  }
  try {
    const config = await HOST_FUNCTIONS.getCurrentConfig();
    filePathsValues = { ...(config.baseline || {}), ...(config.user || {}) };
  } catch (e) {
    filePathsValues = {};
  }
  document.getElementById('clear-csv').onclick = () => {
    for (const key of filePathKeys()) {
      if (key !== 'settings.path' && filePathCurrent(key) !== '') filePathsCleared.add(key);
    }
    renderFilePaths();
  };
  renderFilePaths();
});
