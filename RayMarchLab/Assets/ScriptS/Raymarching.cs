using UnityEngine;

[RequireComponent(typeof(Camera))]

[ExecuteInEditMode]
public class Raymarching : MonoBehaviour
{
    [SerializeField]
    private Shader RaymarchShader;

    public Material RaymarchMaterial
    {
        get
        {
            if (!RaymarchMat && RaymarchShader)
            {
                RaymarchMat = new Material(RaymarchShader);
                RaymarchMat.hideFlags = HideFlags.HideAndDontSave;
            }
            return RaymarchMat;
        }
        set
        {
            RaymarchMat = value;
        }
    }
    private Material RaymarchMat;

    public Camera RayCamera
    {
        get
        {
            if (!Cam)
                Cam = GetComponent<Camera>();
            return Cam;
        }
        set
        {
            Cam = value;
        }
    }

    private Camera Cam;
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(!RaymarchMaterial)
        {
            Graphics.Blit(source, destination);
            return;
        }
        RaymarchMaterial.SetMatrix("_CamFrustum", CamFrustum(RayCamera));
        Graphics.Blit(source, destination, RaymarchMaterial);
    }

    private Matrix4x4 CamFrustum(Camera cam)
    {
        Matrix4x4 frustum = Matrix4x4.identity;
        float fov = Mathf.Tan((cam.fieldOfView*0.5f)*Mathf.Deg2Rad);
        Vector3 goUp = Vector3.up * fov;
        Vector3 goRight = Vector3.right * fov * cam.aspect;

        Vector3 TL = (-Vector3.forward - goRight + goUp);
        Vector3 TR = (-Vector3.forward + goRight + goUp);
        Vector3 BR = (-Vector3.forward + goRight - goUp);
        Vector3 BL = (-Vector3.forward - goRight - goUp);
       

        frustum.SetRow(0, TL);
        frustum.SetRow(1, TR);
        frustum.SetRow(2, BR);
        frustum.SetRow(3, BL);
        return frustum;
    }
}
