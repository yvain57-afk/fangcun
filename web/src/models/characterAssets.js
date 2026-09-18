// Artwork identity and cast are explicit; a solo scene never loads a duo image.
export const CHARACTER_ARTWORKS = {
  'dog-greeting': { src: '/characters/v4/dog-greeting.png', cast: 'dog', pose: 'relaxed' },
  'dog-rest': { src: '/characters/v4/dog-rest.png', cast: 'dog', pose: 'support' },
  'dog-drink': { src: '/characters/v4/dog-drink.png', cast: 'dog', pose: 'cup' },
  'cat-curious': { src: '/characters/v4/cat-curious.png', cast: 'cat', pose: 'curious' },
  'duo-calm': { src: '/characters/v4/duo-calm.png', cast: 'duo', pose: 'relaxed' },
  'duo-complete': { src: '/characters/v4/duo-complete.png', cast: 'duo', pose: 'touch' },
  // The accepted solo cat is reused byte-for-byte.
  breathing: { src: '/characters/v3/breathing.png', cast: 'cat', pose: 'breathe' },
};
