import React from 'react';

export default function OLTooltip({ children, description }) {
  return (
    <span title={description} className="ol-tooltip-stub">
      {children}
    </span>
  );
}
