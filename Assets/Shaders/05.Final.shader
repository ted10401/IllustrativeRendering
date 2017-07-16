Shader "Custom/Illustrative Rendering/05.Final"
{
	Properties
	{
		[Header(Main Map)]
		_MainTex ("Albedo", 2D) = "white" {}

		[Header(Warped Diffuce)]
		_WarpedTex ("Warped Texture", 2D) = "white" {}
		_WarpedScale ("Warped Scale", Float) = 1

		[Header(Specular)]
		_SpecularMask ("Specular Mask", 2D) = "white" {}
		_Fspec ("Fresnel Specular Term", Float)  = 1
		_Kspec ("Specular Exponent Power", Float) = 1

		[Header(Rim)]
		_RimMask ("Rim Mask", 2D) = "white" {}
		_RimPower ("Rim Power", Float) = 4
		_Krim ("Rim Exponent Power", Float) = 1
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
				half3 NdotL : TEXCOORD1;
				half3 VdotR : TEXCOORD2;
				half3 VdotN : TEXCOORD3;
				half3 NdotU : TEXCOORD4;
			};

			sampler2D _MainTex;
			half4 _MainTex_ST;

			sampler2D _WarpedTex;
			half4 _WarpedTex_ST;
			half _WarpedScale;

			sampler2D _SpecularMask;
			half4 _SpecularMask_ST;
			half _Fspec;
			half _Kspec;

			sampler2D _RimMask;
			half4 _RimMask_ST;
			half _RimPower;
			half _Krim;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				half3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
				half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				o.NdotL = dot(worldNormal, lightDir);

				half3 viewDir = normalize(WorldSpaceViewDir(v.vertex));
				half3 reflectDir = reflect(-lightDir, worldNormal);
				o.VdotR = saturate(dot(viewDir, reflectDir));
				o.VdotN = saturate(dot(viewDir, worldNormal));

				half3 worldUp = half3(0, 1, 0);
				o.NdotU = dot(worldNormal, worldUp);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//View Independent Lighting
				half4 k = tex2D(_MainTex, i.uv);
				half halfLambert = pow(0.5 * i.NdotL + 0.5, 2);
				half2 warpedUV = float2(halfLambert, halfLambert);
				half3 diffuseWarping = tex2D(_WarpedTex, warpedUV).rgb * _WarpedScale;

				half3 viewIndependentLight = k * _LightColor0.rgb * diffuseWarping;


				//View Dependent Lighting
				//Multiple Phong Terms
				half4 ks = tex2D( _SpecularMask, i.uv);
                half3 specularTerm = _Fspec * pow(i.VdotR, _Kspec);

                half fresnelRim = pow(1 - i.VdotN, _RimPower);
				half4 kr = tex2D(_RimMask, i.uv);
                half3 rimTerm = fresnelRim * kr * pow(i.VdotR, _Krim);

                half3 multiplePhongTerms = _LightColor0.rgb * ks * max(specularTerm, rimTerm);

                //Dedicated Rim Lighting
                half3 dedicatedRimLighting = i.NdotU * fresnelRim * kr;

                half3 viewDependentLight = multiplePhongTerms + dedicatedRimLighting;


                //Final Result
                fixed4 finalColor;
                finalColor.rgb = viewIndependentLight + viewDependentLight;
                finalColor.a = 1;

				return finalColor;
			}
			ENDCG
		}
	}
}
