#include <metal_stdlib>
using namespace metal;
float fcArea(float2 p, float2 c, float2 r) { float2 q=(p-c)/r; float a=clamp(1-dot(q,q),0.0,1.0); return a*a; }
float fcHead(float2 p, float2 c, float2 r) { float e=clamp((1-length((p-c)/r))/.4,0.0,1.0); return e*e*(3-2*e); }
float fcGesture(float t,float d) { if(t<=0 || t>=d) return 0; float s=sin(M_PI_F*t/d); return s*s; }
[[ stitchable ]] float2 fangcunCompanionWarp(float2 position, float2 size, float mode, float time, float breath, float reduced) {
 if(reduced>0.5) return position;
 float2 p=position/max(size,float2(1)), delta=0;
 float grounded=clamp((.79-p.y)/.11,0.0,1.0);
 if(mode<.5) {
  float hello=fcGesture(time,1.8), wag=hello*sin(time*5);
  float tail=fcArea(p,float2(.80,.74),float2(.10,.12));
  float head=fcHead(p,float2(.67,.43),float2(.22,.28))*grounded;
  delta=float2(.015,-.010)*wag*tail+float2(-(p.y-.43),p.x-.67)*.025*hello*head;
 } else if(mode<1.5) {
  delta.y=-.0045*(1-cos(time*M_PI_F/4))/2*fcArea(p,float2(.72,.53),float2(.18,.20))*grounded;
 } else if(mode<2.5) {
  float look=fcGesture(time,1.6)*fcHead(p,float2(.54,.43),float2(.31,.32))*grounded;
  delta=float2(.008-(p.y-.43)*.024,.004+(p.x-.54)*.024)*look;
 } else if(mode<3.5) {
  delta.y=.014*fcGesture(time,.85)*fcHead(p,float2(.51,.43),float2(.30,.30))*grounded;
 } else if(mode<4.5) {
  float chest=fcArea(p,float2(.52,.58),float2(.35,.32))*clamp((.82-p.y)/.16,0.0,1.0);
  delta=float2((p.x-.52)*.065,-.018)*breath*chest;
 } else {
  float touch=fcGesture(time,1.3)*fcArea(p,float2(.51,.61),float2(.15,.14));
  delta=float2(p.x<.5?.007:-.007,-.005)*touch;
 }
 return position-delta*size;
}

// Remove only near-neutral paper pixels, retaining the colored print and its texture.
// Both appearances use the same ink; no color inversion or opaque white tile.
[[ stitchable ]] half4 fangcunPaperAlpha(float2 position, half4 color) {
 half low=min(color.r,min(color.g,color.b));
 half high=max(color.r,max(color.g,color.b));
 half paper=smoothstep(half(.90),half(.985),low)*(1-smoothstep(half(.035),half(.08),high-low));
 return color*(1-paper);
}
