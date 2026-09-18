import { useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { motion } from 'framer-motion';
import { MOTION } from '../models/motionTokens.js';

export default function Modal({ children, label, onClose, reduced, className = '' }) {
  const ref = useRef(null);
  useEffect(() => {
    const previous = document.activeElement;
    const dialog = ref.current;
    const selector = 'button:not(:disabled), select, input, [href], [tabindex="0"]';
    (dialog.querySelector(selector) || dialog).focus();
    const app = document.querySelector('.app-content');
    if (app) app.inert = true;
    function handle(event) {
      if (event.key === 'Escape') { event.preventDefault(); onClose(); }
      if (event.key === 'Tab') {
        const nodes = [...dialog.querySelectorAll(selector)].filter(node => node.getClientRects().length);
        if (!nodes.length) { event.preventDefault(); return; }
        if (event.shiftKey && document.activeElement === nodes[0]) { event.preventDefault(); nodes.at(-1).focus(); }
        else if (!event.shiftKey && document.activeElement === nodes.at(-1)) { event.preventDefault(); nodes[0].focus(); }
      }
    }
    dialog.addEventListener('keydown', handle);
    return () => { dialog.removeEventListener('keydown', handle); if (app) app.inert = false; if (previous?.isConnected) previous.focus(); };
  }, [onClose]);
  const host = document.getElementById('overlay-host');
  if (!host) return null;
  return createPortal(<div className={`modal-backdrop ${className}`} onPointerDown={e => { if (e.target === e.currentTarget) onClose(); }}>
    <motion.section ref={ref} role="dialog" aria-modal="true" aria-label={label} tabIndex={-1} className="modal-panel"
      initial={reduced ? false : { opacity: 0, transform: 'translateY(24px)' }} animate={{ opacity: 1, transform: 'translateY(0px)' }} transition={{ duration: MOTION.modalEntry, ease: MOTION.easeOut }}>
      {children}
    </motion.section>
  </div>, host);
}
