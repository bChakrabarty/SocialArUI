﻿// Upgrade NOTE: replaced 'UNITY_INSTANCE_ID' with 'UNITY_VERTEX_INPUT_INSTANCE_ID'

/*========================================================================
Copyright (c) 2017 PTC Inc. All Rights Reserved.

Vuforia is a trademark of PTC Inc., registered in the United States and other
countries.
=========================================================================*/
Shader "Custom/DepthContourHL" {
    Properties
    {
        _ContourColor("Contour Color", Color) = (1,1,1,1)
        _SurfaceColor("Surface Color", Color) = (0.5,0.5,0.5,1)
        _DepthThreshold("Depth Threshold", Float) = 0.002
    }

        SubShader{
        Tags { "Queue" = "Geometry" "RenderType" = "Transparent" }

        Pass
        {
            Cull Back
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"

        uniform sampler2D _CameraDepthTexture;
    //uniform float4 _ContourColor;
    uniform float4 _SurfaceColor;
    uniform float _DepthThreshold;

    struct appdata
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct v2f
    {
        float4 pos : SV_POSITION;
        float4 screenPos : TEXCOORD0;
        float depth : TEXCOORD1;
        UNITY_VERTEX_INPUT_INSTANCE_ID
        UNITY_VERTEX_OUTPUT_STEREO
    };

    // appdata_base v
    v2f vert(appdata v)
    {
        v2f o;
        // Single-pass instanced
        UNITY_SETUP_INSTANCE_ID(v);
        UNITY_TRANSFER_INSTANCE_ID(v, o);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
        // end
        o.pos = UnityObjectToClipPos(v.vertex);
        o.screenPos = ComputeScreenPos(o.pos);

        COMPUTE_EYEDEPTH(o.depth);
        o.depth = (o.depth - _ProjectionParams.y) / (_ProjectionParams.z - _ProjectionParams.y);
        return o;
    }

    //UNITY_DECLARE_SCREENSPACE_TEXTURE(_MainTex);
    //UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

    UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_DEFINE_INSTANCED_PROP(float4, _ContourColor)
        UNITY_INSTANCING_BUFFER_END(Props)

    half4 frag(v2f i) : COLOR
    {
        UNITY_SETUP_INSTANCE_ID(i);
    //UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i)

        //fixed4 col = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_MainTex, i.uv);

        //fixed4 col = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.depth);

            float2 uv = i.screenPos.xy / i.screenPos.w;
            float du = 1.0 / _ScreenParams.x;
            float dv = 1.0 / _ScreenParams.y;
            float2 uv_X1 = uv + float2(du, 0.0);
            float2 uv_Y1 = uv + float2(0.0, dv);
            float2 uv_X2 = uv + float2(-du, 0.0);
            float2 uv_Y2 = uv + float2(0.0, -dv);

            float depth0 = Linear01Depth(UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, uv)));
            float depthX1 = Linear01Depth(UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, uv_X1)));
            float depthY1 = Linear01Depth(UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, uv_Y1)));
            float depthX2 = Linear01Depth(UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, uv_X2)));
            float depthY2 = Linear01Depth(UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, uv_Y2)));

            float farDist = _ProjectionParams.z;
            float refDepthStep = _DepthThreshold / farDist;
            float depthStepX = max(abs(depth0 - depthX1), abs(depth0 - depthX2));
            float depthStepY = max(abs(depth0 - depthY1), abs(depth0 - depthY2));
            float maxDepthStep = length(float2(depthStepX, depthStepY));
            half contour = (maxDepthStep > refDepthStep) ? 1.0 : 0.0;
            return _SurfaceColor * (1.0 - contour) + _ContourColor * contour;
    }

    ENDCG
}
    }

        Fallback "Diffuse"
}
