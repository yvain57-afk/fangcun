import test from 'node:test';
import assert from 'node:assert/strict';
import { EMPTY_LOG, changeLog, totalDrinks, countCategory, validLog } from '../src/models/drinks.js';
import { phaseAt, formatTime } from '../src/models/breathing.js';

test('one sweet latte counts fluid, caffeine and a sugary serving exactly once', () => {
  const log = changeLog(EMPTY_LOG, { type: 'add', preset: 'sweetCoffee', coffeeMg: 140 });
  assert.deepEqual(totalDrinks(log.entries), { fluidMl: 300, caffeineMg: 140, alcoholG: 0, sugarServings: 1 });
  assert.equal(countCategory(log.entries, 'coffee'), 1);
  assert.equal(validLog(log), true);
});
test('undo restores an entire composite drink, including undoing a removal', () => {
  const first = changeLog(EMPTY_LOG, { type: 'add', preset: 'sweetCoffee' });
  const second = changeLog(first, { type: 'add', preset: 'water' });
  const third = changeLog(second, { type: 'remove', category: 'coffee' });
  assert.equal(totalDrinks(third.entries).caffeineMg, 0);
  assert.deepEqual(changeLog(third, { type: 'undo' }).entries, second.entries);
  assert.deepEqual(changeLog(changeLog(third, { type: 'undo' }), { type: 'undo' }).entries, first.entries);
});
test('decrement cannot create negative quantities or spurious undo actions', () => {
  assert.equal(changeLog(EMPTY_LOG, { type: 'remove', category: 'water' }), EMPTY_LOG);
  assert.equal(changeLog(EMPTY_LOG, { type: 'undo' }), EMPTY_LOG);
});
test('changed caffeine presets only affect future records', () => {
  let log = changeLog(EMPTY_LOG, { type: 'add', preset: 'coffee', coffeeMg: 140 });
  log = changeLog(log, { type: 'add', preset: 'coffee', coffeeMg: 90 });
  assert.equal(totalDrinks(log.entries).caffeineMg, 230);
  assert.equal(log.entries[0].caffeineMg, 140);
});
test('invalid persisted log data is rejected', () => {
  assert.equal(validLog({ entries: [{ preset: 'fake' }], history: [] }), false);
  assert.equal(validLog({ entries: ['water'], history: [] }), false);
});
test('double-inhale phases and scale remain continuous at cycle boundaries', () => {
  assert.equal(phaseAt(3.999).id, 'inhale');
  assert.equal(phaseAt(4).id, 'topup');
  assert.equal(phaseAt(5).id, 'exhale');
  assert.equal(phaseAt(12).id, 'inhale');
  assert.ok(Math.abs(phaseAt(3.999).scale - phaseAt(4).scale) < .001);
  assert.ok(Math.abs(phaseAt(4.999).scale - phaseAt(5).scale) < .001);
  assert.ok(Math.abs(phaseAt(11.999).scale - phaseAt(12).scale) < .001);
  assert.equal(phaseAt(300).complete, true);
  assert.equal(phaseAt(299).cycle, 25);
  assert.equal(formatTime(299.1), '5:00');
  assert.equal(formatTime(-1), '0:00');
});

import { CHARACTER_ARTWORKS } from '../src/models/characterAssets.js';
import { deformArtworkPoint } from '../src/models/characterMotion.js';
test('generated-art motion preserves planted feet and all edges across the entire breath', () => {
  for (let breath = 0; breath <= 1; breath += .1) {
    for (const [x, y] of [[.45,.85],[.58,.85],[.7,.85],[0,0],[1,0],[0,1],[1,1]]) {
      assert.deepEqual(deformArtworkPoint(x,y,{asset:'breathing',breath}),[x,y]);
    }
  }
  const exhaled = deformArtworkPoint(.65,.58,{asset:'breathing',breath:0});
  const inhaled = deformArtworkPoint(.65,.58,{asset:'breathing',breath:1});
  assert.ok(inhaled[0] > exhaled[0]);
  assert.ok(inhaled[1] < exhaled[1]);
});
test('reduced motion preserves every sampled source point and gestures stay within local bounds', () => {
  for (const asset of Object.keys(CHARACTER_ARTWORKS)) {
    for (let x=0;x<=1;x+=.1) for(let y=0;y<=1;y+=.1) {
      assert.deepEqual(deformArtworkPoint(x,y,{asset,time:1,breath:1,reduced:true}),[x,y]);
      const [a,b]=deformArtworkPoint(x,y,{asset,time:1,breath:1});
      assert.ok(Math.hypot(a-x,b-y)<.022);
    }
  }
});


test('a puppy nod preserves spacing between eyes and nose', () => {
  const landmarks = [[.4,.4],[.5,.43],[.6,.45]];
  const moved = landmarks.map(([x,y]) => deformArtworkPoint(x,y,{asset:'dog-drink',time:.425,reaction:true}));
  for (let i=1;i<landmarks.length;i++) {
    const before = Math.hypot(landmarks[i][0]-landmarks[0][0],landmarks[i][1]-landmarks[0][1]);
    const after = Math.hypot(moved[i][0]-moved[0][0],moved[i][1]-moved[0][1]);
    assert.ok(Math.abs(before-after)<1e-8);
  }
});
