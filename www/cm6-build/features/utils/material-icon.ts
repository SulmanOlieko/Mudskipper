export function materialIcon(name: string): HTMLElement {
  const i = document.createElement('i');
  // mapping material icon names roughly to tabler
  const map: Record<string, string> = {
    'edit': 'ti-pencil',
    'image': 'ti-photo',
    'warning': 'ti-alert-triangle'
  };
  i.className = `ti ${map[name] || 'ti-' + name}`;
  const span = document.createElement('span');
  span.appendChild(i);
  return span;
}
