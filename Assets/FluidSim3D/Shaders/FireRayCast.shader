// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'


Shader "3DFluidSim/FireRayCast" 
{
	Properties
	{
		_FireGradient("FireGradient", 2D) = "red" {}
		_SmokeColor("SmokeGradient", Color) = (0,0,0,1)
		_SmokeAbsorption("SmokeAbsorbtion", float) = 60.0
		_FireAbsorption("FireAbsorbtion", float) = 40.0
	}
	SubShader 
	{
		Tags { "Queue" = "Transparent" }
	
    	Pass 
    	{
    	
    		Cull front
    		Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#include "UnityCG.cginc"
			#pragma target 5.0
			#pragma vertex vert
			#pragma fragment frag
			
			#define NUM_SAMPLES 64
			
			sampler2D _FireGradient;
			float4 _SmokeColor;
			float _SmokeAbsorption, _FireAbsorption;
			uniform float3 _Translate, _Scale, _Size;
			
			StructuredBuffer<float> _Density, _Reaction;
		
			struct v2f 
			{
    			float4 pos : SV_POSITION;
    			float3 worldPos : TEXCOORD0;
			};

			v2f vert(appdata_base v)
			{
    			v2f OUT;
    			OUT.pos = UnityObjectToClipPos(v.vertex);
    			OUT.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
    			return OUT;
			}
			
			struct Ray {
				float3 origin;
				float3 dir;
			};
			
			struct AABB {
			    float3 Min;
			    float3 Max;
			};
			
			//find intersection points of a ray with a box
			bool intersectBox(Ray r, AABB aabb, out float t0, out float t1)
			{
			    float3 invR = 1.0 / r.dir;
			    float3 tbot = invR * (aabb.Min-r.origin);
			    float3 ttop = invR * (aabb.Max-r.origin);
			    float3 tmin = min(ttop, tbot);
			    float3 tmax = max(ttop, tbot);
			    float2 t = max(tmin.xx, tmin.yz);
			    t0 = max(t.x, t.y);
			    t = min(tmax.xx, tmax.yz);
			    t1 = min(t.x, t.y);
			    return t0 <= t1;
			}
			
			float SampleBilinear(StructuredBuffer<float> buffer, float3 uv, float3 size)
			{
				uv = saturate(uv);
				uv = uv * (size-1.0);
			
				int x = uv.x;
				int y = uv.y;
				int z = uv.z;
				
				int X = size.x;
				int XY = size.x*size.y;
				
				float fx = uv.x-x;
				float fy = uv.y-y;
				float fz = uv.z-z;
				
				int xp1 = min(_Size.x-1, x+1);
				int yp1 = min(_Size.y-1, y+1);
				int zp1 = min(_Size.z-1, z+1);
				
				float x0 = buffer[x+y*X+z*XY] * (1.0f-fx) + buffer[xp1+y*X+z*XY] * fx;
				float x1 = buffer[x+y*X+zp1*XY] * (1.0f-fx) + buffer[xp1+y*X+zp1*XY] * fx;
				
				float x2 = buffer[x+yp1*X+z*XY] * (1.0f-fx) + buffer[xp1+yp1*X+z*XY] * fx;
				float x3 = buffer[x+yp1*X+zp1*XY] * (1.0f-fx) + buffer[xp1+yp1*X+zp1*XY] * fx;
				
				float z0 = x0 * (1.0f-fz) + x1 * fz;
				float z1 = x2 * (1.0f-fz) + x3 * fz;
				
				return z0 * (1.0f-fy) + z1 * fy;
				
			}

			
			float4 frag(v2f IN) : COLOR
			{
				float3 pos = _WorldSpaceCameraPos;
			
				Ray r;
				r.origin = pos;
				r.dir = normalize(IN.worldPos-pos);
				
				AABB aabb;
				aabb.Min = float3(-0.5,-0.5,-0.5)*_Scale + _Translate;
				aabb.Max = float3(0.5,0.5,0.5)*_Scale + _Translate;

				//figure out where ray from eye hit front of cube
				float tnear, tfar;
				intersectBox(r, aabb, tnear, tfar);
				
				//if eye is in cube then start ray at eye
				if (tnear < 0.0) tnear = 0.0;

				float3 rayStart = r.origin + r.dir * tnear;
    			float3 rayStop = r.origin + r.dir * tfar;
    			
    			//convert to texture space
    			rayStart -= _Translate;
    			rayStop -= _Translate;
   				rayStart = (rayStart + 0.5*_Scale)/_Scale;
   				rayStop = (rayStop + 0.5*_Scale)/_Scale;
  
				float3 start = rayStart;
				float dist = distance(rayStop, rayStart);
				float stepSize = dist/float(NUM_SAMPLES);
			    float3 ds = normalize(rayStop-rayStart) * stepSize;
			    float fireAlpha = 1.0, smokeAlpha = 1.0;
			
   				for(int i=0; i < NUM_SAMPLES; i++, start += ds) 
   				{
   				 
   					float D = SampleBilinear(_Density, start, _Size);
   					
   					float R = SampleBilinear(_Reaction, start, _Size);
   				 	
        			fireAlpha *= 1.0-saturate(R*stepSize*_FireAbsorption);
        			
        			smokeAlpha *= 1.0-saturate(D*stepSize*_SmokeAbsorption);
        			
        			if(fireAlpha <= 0.01 && smokeAlpha <= 0.01) break;
			    }
			    
			    float4 smoke = _SmokeColor * (1.0-smokeAlpha);
			    
			    float4 fire = tex2D(_FireGradient, float2(fireAlpha,0)) * (1.0-fireAlpha);
			    
				return fire + smoke;
			}
			
			ENDCG

    	}
	}
}





















