using System.Collections;
using System;
using System.Collections.Generic;
using UnityEngine;

public class WaterBottle : MonoBehaviour
{
    public float SinSpeed;
    Material Bottle;
    Vector3 LastPos;
    Vector3 forceDir;
    // Vector3 LastFDir;
    List<ForceDir> ForceList;
    
    float damping;
    int cnt;

    public class ForceDir : IComparable<ForceDir>
    {
        public Vector3 forceDir;
        public float selfdamping;

        public ForceDir()
        {
            forceDir = new Vector3();
            selfdamping = 1;
        }
        public ForceDir(Vector3 Force, float damping)
        {
            forceDir = Force;
            selfdamping = damping;
        }

        public int CompareTo(ForceDir obj_)
        {
            if (this.forceDir.magnitude*this.selfdamping > obj_.forceDir.magnitude*obj_.selfdamping)
                return 1;
            else
                return -1;
        }
    }
    // Start is called before the first frame update
    private void Awake() {
        ForceList = new List<ForceDir>();
        cnt = 0;
        damping = 1;
    }
    void Start()
    {
        forceDir = new Vector3(0, 0, 0);
        // LastFDir = new Vector3(0, 0, 0);
        LastPos = transform.position;
        Bottle = gameObject.GetComponent<Renderer>().material;
    }

    // Update is called once per frame
    void Update()
    {
        if(ForceList.Count > 0)
            ForceList.Sort();
        forceDir = transform.position - LastPos;

        if(ForceList.Count < 10)
        {
            ForceList.Add(new ForceDir(forceDir, 1));
        }
        else if(forceDir.magnitude > ForceList[0].forceDir.magnitude * ForceList[0].selfdamping)
        {
            ForceList.RemoveAt(0);
            ForceList.Add(new ForceDir(forceDir, 1));
        }
        Vector3 LastFDir = new Vector3(0, 0, 0);
        foreach(ForceDir t in ForceList)
        {
            // Debug.Log(t.forceDir.magnitude);

            LastFDir += t.forceDir*t.selfdamping;

            t.selfdamping *= 0.99f;
        }
        Debug.Log(LastFDir);


        // if(forceDir.magnitude > LastFDir.magnitude * damping)
        // {
        //     LastFDir = forceDir;
        //     damping = 1;
        // }
        // damping *= 0.99f;

        LastPos = transform.position;

        // Vector3 SinForceDir = damping * LastFDir * Mathf.Sin(SinSpeed*Time.time);

        Bottle.SetVector("_ForceDir", LastFDir);
        Bottle.SetVector("_WorldZeroPos", transform.position);
    }
}
