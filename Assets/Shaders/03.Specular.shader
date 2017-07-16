Shader "Custom/Illustrative Rendering/03.Specular"
{
	Properties
	{
		_SpecularMask ("Specular Mask", 2D) = "white" {}
		_Fspec ("Fresnel Specular Term", Float)  = 1
		_Kspec ("Specular Exponent Power", Float) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				half3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				half3 VdotR : TEXCOORD1;
			};

			sampler2D _SpecularMask;
			half4 _SpecularMask_ST;
			half _Fspec;
			half _Kspec;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _SpecularMask);

				half3 worldNormal = UnityObjectToWorldNormal(v.normal);
				half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				half3 reflectDir = reflect(-lightDir, worldNormal);
				half3 viewDir = normalize(WorldSpaceViewDir(v.vertex));
				o.VdotR = saturate(dot(viewDir, reflectDir));

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half4 ks = tex2D( _SpecularMask, i.uv);
                half3 specularTerm = _Fspec * pow(i.VdotR, _Kspec);

                fixed4 col;
                col.rgb = _LightColor0.rgb * ks * specularTerm;
                col.a = 1;

				return col;
			}
			ENDCG
		}
	}
}
