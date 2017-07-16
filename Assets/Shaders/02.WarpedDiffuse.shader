Shader "Custom/Illustrative Rendering/02.WarpedDiffuse"
{
	Properties
	{
		_WarpedTex ("Warped Texture", 2D) = "white" {}
		_WarpedScale ("Warped Scale", Float) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" }

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
				half NdotL : TEXCOORD1;
			};

			sampler2D _WarpedTex;
			half4 _WarpedTex_ST;
			half _WarpedScale;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _WarpedTex);

				half3 worldNormal = UnityObjectToWorldNormal(v.normal);
				half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				o.NdotL = dot(worldNormal, lightDir);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half halfLambert = pow(0.5 * i.NdotL + 0.5, 2);
				half2 warpedUV = float2(halfLambert, halfLambert);
				half3 diffuseWarping = tex2D(_WarpedTex, warpedUV).rgb * _WarpedScale;

				fixed4 finalColor;
				finalColor.rgb = diffuseWarping;

				return finalColor;
			}
			ENDCG
		}
	}
}
