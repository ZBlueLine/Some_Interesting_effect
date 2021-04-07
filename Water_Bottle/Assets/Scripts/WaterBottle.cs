using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WaterBottle : MonoBehaviour
{
    public float SinSpeed;
    Material Bottle;
    Vector3 LastPos;
    Vector3 forceDir;
    Vector3 LastFDir;
    
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
        LastPos = transform.position;
        Bottle = gameObject.GetComponent<Renderer>().material;
    }

    // Update is called once per frame
    void Update()
    {
        
        forceDir = transform.position - LastPos;
        forceDir*=3;
        if(forceDir.magnitude > LastFDir.magnitude * damping)
        {
            LastFDir = forceDir;
            damping = 1;
        }
        damping *= 0.99f;

        LastPos = transform.position;

        Vector3 SinForceDir = damping * LastFDir * Mathf.Sin(SinSpeed*Time.time);

        Bottle.SetVector("_ForceDir", SinForceDir);
        Bottle.SetVector("_WorldZeroPos", transform.position);
        Debug.Log(transform.position);
    }
}
