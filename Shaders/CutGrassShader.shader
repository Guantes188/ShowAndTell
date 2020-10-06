Shader "Custom/CutGrassShader"
{
    Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Long Grass", 2D) = "white" {}
		_ShortTex("Short Grass", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0

		_NsTex("North/South pattern", 2D) = "white" {}
		_EwTex("East/West pattern", 2D) = "white" {}
		_CutTex("Cut pattern", 2D) = "gray" {}

		_CutTexRepeat("Cut Texture Repeat", Range(0.1, 100.0)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
		sampler2D _ShortTex;
		sampler2D _NsTex;
		sampler2D _EwTex;
		sampler2D _CutTex;

		float4 _MainTex_TexelSize;
		float4 _NsTex_TexelSize;
		float4 _EwTex_TexelSize;

		half _CutTexRepeat;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			fixed4 cut_colour = tex2D(_CutTex, IN.uv_MainTex);

			// Determine a cut direction which will allow us to flip the texture.
			fixed2 direction = fixed2(
				lerp(-1, 1, cut_colour.r),
				lerp(-1, 1, cut_colour.g));

			// Determine the UV coordinates for the NS and EW textures. This allows
			// us to scale the textures to make them a better fit for detail size.
			// (Repeat is based on the ratio of the main and NS/EW texture sizes and
			// the repeat slider value.)
			// (UV is based on the main UV, the repeat value and the direction - for
			// texture flipping.)
			half main_tex_repeat = _CutTexRepeat * _MainTex_TexelSize.z;
			half ns_repeat = main_tex_repeat / _NsTex_TexelSize.z;
			float2 uv_NsTex = IN.uv_MainTex * ns_repeat * direction.x;

			half ew_repeat = main_tex_repeat / _EwTex_TexelSize.z;
			float2 uv_EwTex = IN.uv_MainTex * ew_repeat * direction.y;

			// Determine the base texture (either long grass or short grass).
			// We use the absolute direction to stack repeated cuts and to treat any
			// direction of cut as significant.
			fixed4 base_colour = lerp(tex2D(_MainTex, IN.uv_MainTex), tex2D(_ShortTex, IN.uv_MainTex), cut_colour.a);

			// Determine the pattern of cut (NS, EW, or a combination of the two).
			// Lerped against a completely average texture.
			fixed4 no_pattern_colour = fixed4(.5, .5, .5, 1);
			fixed4 pattern_colour =
				(lerp(no_pattern_colour, tex2D(_NsTex, uv_NsTex), abs(direction.x)) +
				lerp(no_pattern_colour, tex2D(_EwTex, uv_EwTex), abs(direction.y))) / 2;

			// Use the pattern to tint the base colour, not replace it.
			fixed4 c = lerp(base_colour, pattern_colour, cut_colour.a * 0.2f) * _Color;
			o.Albedo = c.rgb;

			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
