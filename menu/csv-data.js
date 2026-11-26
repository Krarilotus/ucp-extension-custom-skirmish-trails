// Export / Import CSV Data panel. The GUI cannot write files for a module, so a button only
// records a request (action + a time stamp); the game carries it out once at its next start.

let csvDataPending = null;
const csvDataLabels = {};

SANDBOX_FUNCTIONS.getConfig = () =>
  csvDataPending === null
    ? {}
    : { action: csvDataPending.action, request: csvDataPending.request };

function csvDataText(id, text) {
  const element = document.getElementById(id);
  if (element) element.textContent = text;
}

function csvDataRequest(action) {
  csvDataPending = { action, request: new Date().toISOString() };
  for (const id of ['export', 'import']) {
    const button = document.getElementById(id);
    if (button) button.classList.toggle('chosen', id === action);
  }
  csvDataText('pending', csvDataLabels.requested.replace('{action}', csvDataLabels[action]));
}

addEventListener('INIT_DONE', async () => {
  for (const id of ['export', 'import', 'requested', 'saved']) {
    csvDataLabels[id] = (await HOST_FUNCTIONS.getLocalizedString(`menu_csv_${id}`)) ?? id;
  }
  const exportButton = document.getElementById('export');
  const importButton = document.getElementById('import');
  if (exportButton) exportButton.onclick = () => csvDataRequest('export');
  if (importButton) importButton.onclick = () => csvDataRequest('import');

  try {
    const config = await HOST_FUNCTIONS.getCurrentConfig();
    const values = { ...(config.baseline || {}), ...(config.user || {}) };
    if (values.action && values.request) {
      csvDataText(
        'pending',
        csvDataLabels.saved
          .replace('{action}', csvDataLabels[values.action] ?? values.action)
          .replace('{time}', values.request),
      );
    }
  } catch (e) {
    // no saved request
  }
});
