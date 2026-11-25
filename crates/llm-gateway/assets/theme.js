const STORED_THEME = "llm-gateway.theme";
const root = document.documentElement;
const systemTheme = () => (matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light");
function chosenTheme() {
  try { return localStorage.getItem(STORED_THEME); } catch { return null; }
}
function show(theme) {
  if (theme) root.dataset.theme = theme; else delete root.dataset.theme;
}

show(chosenTheme());
addEventListener("storage", () => show(chosenTheme()));
document.addEventListener("click", (event) => {
  if (!event.target.closest?.("#theme")) return;
  const other = (root.dataset.theme ?? systemTheme()) === "dark" ? "light" : "dark";
  const choice = other === systemTheme() ? null : other;
  show(choice);
  try {
    if (choice) localStorage.setItem(STORED_THEME, choice); else localStorage.removeItem(STORED_THEME);
  } catch {}
});
