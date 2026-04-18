import React from 'react';

const OLPopover = React.forwardRef(({ children, className }, ref) => {
  return (
    <div ref={ref} className={`ol-popover-stub ${className || ''}`} style={{background: 'var(--tblr-bg-surface)', border: '1px solid var(--tblr-border-color)', borderRadius: '4px', padding: '4px'}}>
      {children}
    </div>
  );
});

export default OLPopover;
