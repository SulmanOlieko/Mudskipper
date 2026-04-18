import React from 'react';

export default function MaterialIcon({ type }) {
  const map = {
    'edit': 'ti-pencil',
    'image': 'ti-photo',
    'warning': 'ti-alert-triangle',
    'expand_more': 'ti-chevron-down',
    'check': 'ti-check'
  };
  return <i className={`ti ${map[type] || 'ti-' + type}`} />;
}
