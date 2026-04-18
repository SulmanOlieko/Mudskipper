import React from 'react';

export default function OLOverlay({ show, children }) {
  if (!show) return null;
  return (
    <div className="ol-overlay-stub" style={{position: 'absolute', zIndex: 1000}}>
      {children}
    </div>
  );
}
