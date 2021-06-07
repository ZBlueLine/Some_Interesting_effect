using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class GenerateTextureFromRT : MonoBehaviour
{
    [SerializeReference]
    private RenderTexture CausticRT;
    [SerializeReference]
    private Material CausticMat;

    public void saveRenderTexture(RenderTexture renderTexture, string file)
    {
        RenderTexture.active = renderTexture;
        Texture2D texture = new Texture2D(renderTexture.width, renderTexture.height, TextureFormat.ARGB32, false, false);
        texture.ReadPixels(new Rect(0, 0, renderTexture.width, renderTexture.height), 0, 0);
        texture.Apply();

        byte[] bytes = texture.EncodeToPNG();
        UnityEngine.Object.Destroy(texture);

        System.IO.File.WriteAllBytes(file, bytes);
        Debug.Log("write to File over");
        UnityEditor.AssetDatabase.Refresh(); //自动刷新资源
    }
    // Start is called before the first frame update
    void Start()
    {
        CommandBuffer cb = new CommandBuffer();
        cb.SetRenderTarget(CausticRT);
        cb.Blit(null, CausticRT, CausticMat);
        Camera.main.AddCommandBuffer(CameraEvent.BeforeDepthTexture, cb);
    }

    // Update is called once per frame
    void Update()
    {
    }
}
