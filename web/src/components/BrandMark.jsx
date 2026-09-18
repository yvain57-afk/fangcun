import { useId } from 'react';

// Two open curves hold a small inner space. Large and small instances share the same silhouette.
export default function BrandMark({ className = '', mono = false }) {
  const clip = useId();
  return <svg className={`brand-symbol ${className}`} viewBox="0 0 100 100" fill="currentColor" aria-hidden="true" focusable="false">
    <path d="M57 9C43 7 21 19 10 34C1 47 3 65 15 70C24 74 32 66 28 57C23 46 29 38 40 34C46 32 51 32 56 32C67 32 72 22 67 15C65 11 61 9 57 9Z" /><path d="M43 91C57 93 79 81 90 66C99 53 97 35 85 30C76 26 68 34 72 43C77 54 71 62 60 66C54 68 49 68 44 68C33 68 28 78 33 85C35 89 39 91 43 91Z" />
    {!mono && <><defs><clipPath id={clip}><path d="M43 91C57 93 79 81 90 66C99 53 97 35 85 30C76 26 68 34 72 43C77 54 71 62 60 66C54 68 49 68 44 68C33 68 28 78 33 85C35 89 39 91 43 91Z" /></clipPath></defs><path d="M69 25H103V62C93 52 81 46 70 49Z" fill="var(--accent)" clipPath={`url(#${clip})`} /></>}
  </svg>;
}
