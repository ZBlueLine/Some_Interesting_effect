using UnityEngine;
using System.Collections;

public class ExampleClass : MonoBehaviour
{
    private ParticleSystem ps;
    private ParticleSystem sps;
    public bool splitSubEmitterRibbons = true;

    void Start()
    {
        ps = GetComponent<ParticleSystem>();

        var main = ps.main;
        main.startColor = new ParticleSystem.MinMaxGradient(Color.red, Color.yellow);
        main.startSize = new ParticleSystem.MinMaxCurve(0.00001f, 0.001f);
        main.startLifetime = 9999f;

        main.maxParticles = 1;
        sps = new GameObject("SubEmitter", typeof(ParticleSystem)).GetComponent<ParticleSystem>();
        sps.transform.parent = ps.transform;

        var sub = ps.subEmitters;
        sub.enabled = true;
        sub.AddSubEmitter(sps, ParticleSystemSubEmitterType.Birth, ParticleSystemSubEmitterProperties.InheritColor);

        var smain = sps.main;
        smain.startSpeed = 0.0f;

        var sshape = sps.shape;
        sshape.enabled = false;

        var strails = sps.trails;
        strails.enabled = true;
        strails.mode = ParticleSystemTrailMode.Ribbon;
        strails.widthOverTrail = 0.1f;

        var spsr = sps.GetComponent<ParticleSystemRenderer>();
        spsr.renderMode = ParticleSystemRenderMode.None;
        spsr.trailMaterial = new Material(Shader.Find("Sprites/Default"));
    }

    void Update()
    {
        var strails = sps.trails;
        strails.splitSubEmitterRibbons = splitSubEmitterRibbons;
    }

    void OnGUI()
    {
        splitSubEmitterRibbons = GUI.Toggle(new Rect(25, 25, 200, 30), splitSubEmitterRibbons, "Split Sub Emitter Ribbons");
    }
}