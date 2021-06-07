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
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(!RaymarchMat)
        {
            Graphics.Blit(source, destination);
        }
        RaymarchMat.SetMatrix("_CamFrustum", CamFrustum(Cam));
        Graphics.Blit(source, destination , RaymarchMat);
    }
    private Camera Cam;

    private Matrix4x4 CamFrustum(Camera cam)
    {
        Matrix4x4 frustum = Matrix4x4.identity;
        float fov = Mathf.Tan((Cam.fieldOfView*0.5f)*Mathf.Deg2Rad);
        Vector3 goUp = cam.transform.up * fov;
        Vector3 goRight = cam.transform.right * fov * cam.aspect;

        Vector3 TL = cam.transform.forward + goUp - goRight;
        Vector3 TR = cam.transform.forward + goUp + goRight;
        Vector3 BL = cam.transform.forward - goUp - goRight;
        Vector3 BR = cam.transform.forward - goUp + goRight;

        frustum.SetRow(0, TL.normalized);
        frustum.SetRow(1, TR.normalized);
        frustum.SetRow(2, BL.normalized);
        frustum.SetRow(3, BR.normalized);

        return frustum;
    }
}
