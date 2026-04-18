import React, { useState, useRef, useCallback } from 'react';

export default function useDropdown() {
  const [open, setOpen] = useState(false);
  const ref = useRef(null);

  const onToggle = useCallback((nextOpen) => {
    setOpen(nextOpen);
  }, []);

  return { open, onToggle, ref };
}
