using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Es_Effect_BottleWithinLiquid : MonoBehaviour
{
    public float SinSpeed = 9;
    public float FadeSpeed = 1;
    public float ForceScale = 1;
    Material Bottle;
    Vector3 LastPos;
    Vector3 LastAngle;
    Vector3 forceDir;
    Vector3 AngleDir;
    Vector3 LastFDir;
    Vector3 LastFAngleDir;
    
    float damping;
    int cnt;
    // Start is called before the first frame update
    private void Awake() {
        cnt = 0;
        damping = 1;
    }
    void Start()
    {
        forceDir = new Vector3(0, 0, 0);
        LastFDir = new Vector3(0, 0, 0);
        LastFAngleDir = new Vector3(0, 0, 0);

        LastPos = transform.position;
        LastAngle = transform.rotation.eulerAngles;
        Bottle = gameObject.GetComponent<Renderer>().material;
    }

    // Update is called once per frame
    void Update()
    {
        forceDir = transform.position - LastPos;
        AngleDir = transform.rotation.eulerAngles - LastAngle;
        AngleDir *= 0.05f;
        forceDir *= ForceScale;

        LastFDir = Vector3.Lerp(LastFDir, new Vector3(0, 0, 0), Time.deltaTime * FadeSpeed);
        LastFAngleDir = Vector3.Lerp(LastFAngleDir, new Vector3(0, 0, 0), Time.deltaTime * FadeSpeed);
        LastFAngleDir.y = 0;

        Vector3 SinForceDir = LastFDir * Mathf.Cos(SinSpeed*Time.time) + LastFAngleDir * Mathf.Cos(SinSpeed*Time.time);

        Bottle.SetVector("_ForceDir", SinForceDir);
        Bottle.SetVector("_WorldZeroPos", transform.position);
        
        LastFDir += Vector3.ClampMagnitude(forceDir, forceDir.magnitude*0.15f);
        Debug.Log(LastFDir);
        LastFAngleDir += Vector3.ClampMagnitude(AngleDir, 0.006f);

        LastPos = transform.position;
        LastAngle = transform.rotation.eulerAngles;
    }
}
