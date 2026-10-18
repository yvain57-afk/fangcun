#include <metal_stdlib>
using namespace metal;
float fcArea(float2 p, float2 c, float2 r) { float2 q=(p-c)/r; float a=clamp(1-dot(q,q),0.0,1.0); return a*a; }
float fcHead(float2 p, float2 c, float2 r) { float e=clamp((1-length((p-c)/r))/.4,0.0,1.0); return e*e*(3-2*e); }
float fcGesture(float t,float d) { if(t<=0 || t>=d) return 0; float s=sin(M_PI_F*t/d); return s*s; }
[[ stitchable ]] float2 fangcunCompanionWarp(float2 position, float2 size, float mode, float time, float breath, float reduced, float event, float intensity) {
 if(reduced>0.5) return position;
 float2 p=position/max(size,float2(1)), delta=0;
 float grounded=clamp((.79-p.y)/.11,0.0,1.0);
 if(mode<.5) {
  float hello=fcGesture(time,1.8), wag=hello*sin(time*5);
  float tail=fcArea(p,float2(.80,.74),float2(.10,.12));
  float head=fcHead(p,float2(.67,.43),float2(.22,.28))*grounded;
  delta=float2(.015,-.010)*wag*tail+float2(-(p.y-.43),p.x-.67)*.040*hello*head;
 } else if(mode<1.5) {
  delta.y=-.0045*fcGesture(time,1.6)*fcArea(p,float2(.72,.53),float2(.18,.20))*grounded;
 } else if(mode<2.5) {
  float look=fcGesture(time,1.6)*fcHead(p,float2(.54,.43),float2(.31,.32))*grounded;
  delta=float2(.008-(p.y-.43)*.040,.004+(p.x-.54)*.040)*look;
 } else if(mode<3.5) {
  float duration=event>2.5?.6:event>.5?1.1:.8;
  if(event<1.5 || event>2.5) delta.y=.010*fcGesture(time,duration)*fcHead(p,float2(.51,.43),float2(.30,.30))*clamp((.69-p.y)/.10,0.0,1.0);
  if(event>.5 && event<2.5) {
   // Only cup interior moves; rim, base, animal feet remain fixed.
   float cup=fcArea(p,float2(.158,.771),float2(.047,.027));
   delta.y+=(event<1.5?-.008:.008)*fcGesture(time,event<1.5?1.1:.25)*cup;
   if(event<1.5) delta.x+=.005*sin(time*9)*fcGesture(time,1.1)*fcArea(p,float2(.758,.75),float2(.065,.08));
  }
 } else if(mode<4.5) {
  float chest=fcArea(p,float2(.52,.58),float2(.35,.32))*clamp((.82-p.y)/.16,0.0,1.0);
  delta=float2((p.x-.52)*.065,-.018)*breath*chest;
 } else {
  float touch=fcGesture(time,1.3)*fcArea(p,float2(.51,.61),float2(.15,.14));
  delta=float2(p.x<.5?.007:-.007,-.005)*touch;
 }
 return position-delta*size*intensity;
}

// Remove only near-neutral paper pixels, retaining the colored print and its texture.
// Both appearances use the same ink; no color inversion or opaque white tile.
[[ stitchable ]] half4 fangcunPaperAlpha(float2 position, half4 color) {
 half low=min(color.r,min(color.g,color.b));
 half high=max(color.r,max(color.g,color.b));
 half paper=smoothstep(half(.90),half(.985),low)*(1-smoothstep(half(.035),half(.08),high-low));
 return color*(1-paper);
}

// V4 torso-only deformation: top overlap and bottom feet are anchored. The input
// is an authored separate torso sprite, never the complete character raster.
[[ stitchable ]] float2 fangcunV4Torso(float2 position, float2 size, float expansion) {
 float2 p=position/max(size,float2(1));
 float mask=fcArea(p,float2(.5,.48),float2(.52,.48));
 float feet=1-smoothstep(.70,.90,p.y);
 float neck=smoothstep(.08,.25,p.y);
 float2 d=float2((p.x-.5)*.045,-.015)*expansion*mask*feet*neck;
 return position-d*size;
}

// Intact art: chest band reaches the silhouette, but head/ears/feet are fixed.
[[ stitchable ]] float2 fangcunV4IntactBody(float2 position, float2 size, float pose, float expansion, float attention) {
 float2 p=position/max(size,float2(1));
 float2 d=0;
 if(pose<1.5) {
  float band=smoothstep(.48,.60,p.y)*(1-smoothstep(.70,.84,p.y));
  float xgate=smoothstep(.20,.30,p.x)*(1-smoothstep(.86,.93,p.x));
  float center=pose<.5?.56:.51;
  d=float2((p.x-center)*.12,-.010)*band*xgate*expansion;
 } else if(pose<2.5) {
  float band=smoothstep(.53,.62,p.x)*(1-smoothstep(.83,.92,p.x));
  float grounded=1-smoothstep(.60,.81,p.y);
  d=float2(.004,-.038)*band*grounded*expansion;
 } else if(pose<3.5) {
  float band=smoothstep(.53,.62,p.x)*(1-smoothstep(.83,.93,p.x));
  float grounded=smoothstep(.30,.40,p.y)*(1-smoothstep(.60,.72,p.y));
  d=float2(.008,-.027)*band*grounded*expansion;
 } else if(pose<4.5) {
  // The drawn paw and flag are one connected region. Abdomen never contracts.
  float flag=(1-smoothstep(.23,.40,p.x))*smoothstep(.40,.49,p.y)*(1-smoothstep(.66,.77,p.y));
  d.y=-.030*flag*expansion;
 }
 else if(pose<5.5) {
  float band=smoothstep(.43,.57,p.y)*(1-smoothstep(.78,.87,p.y));
  d.x=(p.x-.53)*.07*band*expansion;
 } else {
  float band=smoothstep(.56,.68,p.x)*(1-smoothstep(.85,.94,p.x));
  d.y=-.025*band*smoothstep(.38,.46,p.y)*(1-smoothstep(.65,.74,p.y))*expansion;
 }
 // A small, finite nod on a spoken return/face cue. No detached head layer.
 float head=pose<1.5 ? fcHead(p,float2(.56,.32),float2(.31,.27)) : fcHead(p,float2(.30,.43),float2(.25,.28));
 d.y+=.006*attention*head;
 return position-d*size;
}
