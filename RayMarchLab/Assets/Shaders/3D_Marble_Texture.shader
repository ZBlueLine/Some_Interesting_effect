Shader "Unlit/3D_Marble_Texture"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Zoom("zoom", Range(0.1, 10)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            float _Zoom;

            float2 cmul( float2 a, float2 b )  { return float2( a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x ); }
            float2 csqr( float2 a )  { return float2( a.x*a.x - a.y*a.y, 2.*a.x*a.y  ); }


            float2x2 rot(float a) {
	            return float2x2(cos(a),sin(a),-sin(a),cos(a));	
            }

            float2 iSphere( in float3 ro, in float3 rd, in float4 sph )//from iq
            {
	            float3 oc = ro - sph.xyz;
	            float b = dot( oc, rd );
	            float c = dot( oc, oc ) - sph.w*sph.w;
	            float h = b*b - c;
	            if( h<0.0 ) return float2(-1.0, -1.0);
	            h = sqrt(h);
	            return float2(-b-h, -b+h );
            }

            float map(in float3 p) {
	
	            float res = 0.;
	
                float3 c = p;
	            for (int i = 0; i < 10; ++i) {
                    p =.7*abs(p)/dot(p,p) -.7;
                    p.yz= csqr(p.yz);
                    p=p.zxy;
                    res += exp(-19. * abs(dot(p,c)));
        
	            }
	            return res/2.;
            }



            float3 raymarch( in float3 ro, float3 rd, float2 tminmax )
            {
                float t = tminmax.x;
                float dt = .02;
                //float dt = .2 - .195*cos(iTime*.05);//animated
                float3 col= float3(0, 0, 0);
                float c = 0.;
                for( int i=0; i<64; i++ )
	            {
                    t+=dt*exp(-2.*c);
                    if(t>tminmax.y)break;
                    float3 pos = ro+t*rd;
        
                    c = map(ro+t*rd);               
        
                    col = .99*col+ .08*float3(c*c, c, c*c*c);//green	
                    //col = .99*col+ .08*float3(c*c*c, c*c, c);//blue
                }    
                return col;
            }

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float time = _Time.y;
                float2 q = i.uv;
                float2 p = -1.0 + 2.0 * q;
                //p.x *= iResolution.x/iResolution.y;
                float2 m = float2(0, 0);

                // camera

                float3 ro = _Zoom*_WorldSpaceCameraPos.xyz;
                //float3 ro = _Zoom*4;
                //ro.yz = mul(rot(m.y), ro.yz);
                //ro.xz = mul(rot(m.x+ 0.1*time), ro.xz);
                float3 ta = float3( 0.0 , 0.0, 0.0 );
                float3 ww = normalize( ta - ro );
                float3 uu = normalize( cross(ww,float3(0.0,1.0,0.0) ) );
                float3 vv = normalize( cross(uu,ww));
                float3 rd = normalize( p.x*uu + p.y*vv + 4.0*ww );
    
                float2 tmm = iSphere( ro, rd, float4(0.,0.,0.,2.));

	            // raymarch
                float3 col = raymarch(ro,rd,tmm);
	
	            // shade
    
                col =  .5 *(log(1.+col));
                col = clamp(col,0.,1.);
                return float4( col, 1.0 );
            }
            ENDCG
        }
    }
}
