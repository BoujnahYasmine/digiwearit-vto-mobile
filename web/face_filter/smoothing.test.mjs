import test from 'node:test';
import assert from 'node:assert/strict';
import {skinPolygons, clampStrength, drawSmoothed} from './smoothing.mjs';
test('No face and incomplete detections leave the original frame untouched', () => {
  for (const face of [undefined, [], Array(20).fill({x:.5,y:.5})]) {
    let draws=0;
    const output={width:720,height:1280,getContext:()=>({clearRect(){},drawImage(){draws++;}})};
    drawSmoothed({}, output, {getContext(){throw Error('Must not blur');}}, face, .7);
    assert.equal(draws,1);
  }
});
test('Off is original even with a face',()=>{
 let draws=0;
 drawSmoothed({}, {width:10,height:10,getContext:()=>({clearRect(){},drawImage(){draws++;}})}, {}, Array(468).fill({x:.5,y:.5}), 0);
 assert.equal(draws,1);
});
test('Invalid strength and landmark coordinates are rejected',()=>{
 assert.equal(clampStrength(NaN),0);assert.equal(clampStrength(-1),0);assert.equal(clampStrength(2),1);
 assert.deepEqual(skinPolygons(Array(468).fill({x:NaN,y:.5}),100,100),[]);
});
test('Mask coordinates scale to captured image resolution',()=>{
 const masks=skinPolygons(Array(468).fill({x:.25,y:.75}),1280,720);
 assert.equal(masks.length,3);assert.deepEqual(masks[0][0],{x:320,y:540});
});
