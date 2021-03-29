using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class DrawRT : MonoBehaviour
{
    public RenderTexture PolarLightRT;
    public GameObject PolarLightPlan;
    RenderTexture standbyRT;
    CommandBuffer Cmd;

    public Material PolarLight;
    // Start is called before the first frame update
    void Start()
    {
        Cmd = new CommandBuffer();  
        standbyRT = RenderTexture.GetTemporary(PolarLightRT.width, PolarLightRT.height, 0, RenderTextureFormat.Default);
        // Cmd.Blit(standbyRT, PolarLightRT);
        Cmd.SetRenderTarget(PolarLightRT);
        Cmd.ClearRenderTarget(true, true, new Color(0f, 0f, 0f, 0f));

        Cmd.SetRenderTarget(standbyRT);
        Cmd.ClearRenderTarget(true, true, new Color(0f, 0f, 0f, 0f));
        
        Renderer Polar = PolarLightPlan.GetComponent<MeshRenderer>();

        Cmd.DrawRenderer(Polar, PolarLight, 0, 0);

        Cmd.Blit(standbyRT, PolarLightRT, PolarLight, 1);

        Camera.main.AddCommandBuffer(CameraEvent.AfterForwardOpaque, Cmd);
        
    }

    // Update is called once per frame
    void Update()
    {
        // Cmd.Blit(standbyRT, PolarLightRT, PolarLight);
    }
}
