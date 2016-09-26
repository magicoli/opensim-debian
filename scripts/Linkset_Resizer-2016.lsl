// Script Name: Linkset_Resizer-2016.lsl
//      also found as resize_script.lsl
// Authors: Brilliant Scientist
//          Ferd Frederix
//          Ann Otoole
//          Gudule Lapointe
// Version: 2016.15
//
//This script uses the llGetLinkPrimitiveParams() and llSetLinkPrimitiveParamsFast() functions introduced in server 1.38 to rescale every prim in an arbitrary linkset. Based on Linkset resizer script by Maestro Linden.
//
//The main differences between the two scripts are:
//
//    * this script is menu-controlled
//    * the script's listen channel is generated dynamically
//    * more comments in the code for beginner scripters
//    * it's just less chatty
//
// Gudule Lapointe's additions:
//    * Fix wrong position when the script is reset while worn
//    * Add "Hide" and "Show" options to minimize the object when hidden
//      (not recommended if only using menus)
//    * To add: option to use Hide and Show buttons
//    * To add: option to show on rez
//
//Special thanks to:
//Ann Otoole for contributing with a script removal function. 

// Downloaded from : http://www.free-lsl-scripts.com/cgi/freescripts.plx?ID=1533

// This program is free software; you can redistribute it and/or modify it.
// Additional Licenes may apply that prevent you from selling this code
// and these licenses may require you to publish any changes you make on request.
//
// There are literally thousands of hours of work in these scripts. Please respect
// the creators wishes and Copyright law and follow their license requirements.
//
// License information included herein must be included in any script you give out or use.
// Licenses may also be included in the script or comments by the original author, in which case
// the authors license must be followed, and  their licenses override any licenses outlined in this header.
//
// You cannot attach a license to any of these scripts to make any license more or less restrictive.
//
// All scripts by avatar Ferd Frederix, unless stated otherwise in the script, are licensed as Creative Commons By Attribution and Non-Commercial.
// Commercial use is NOT allowed - no resale of my scripts in any form.  
// This means you cannot sell my scripts but you can give them away if they are FREE.  
// Scripts by Ferd Frederix may be sold when included in a new object that actually uses these scripts. Putting my script in a prim and selling it on marketplace does not constitute a build.
// For any reuse or distribution, you must make clear to others the license terms of my works. This is done by leaving headers intact.
// See http://creativecommons.org/licenses/by-nc/3.0/ for more details and the actual license agreement.
// You must leave any author credits and any headers intact in any script you use or publish.
///////////////////////////////////////////////////////////////////////////////////////////////////
// If you don't like these restrictions and licenses, then don't use these scripts.
//////////////////////// ORIGINAL AUTHORS CODE BEGINS ////////////////////////////////////////////

// Linkset Resizer with Menu
// version 1.00 (25.04.2010)
// by: Brilliant Scientist
// --
// This script resizes all prims in a linkset, the process is controlled via a menu.
// The script works on arbitrary linksets and requires no configuration.
// The number of prims of the linkset it can process is limited only by the script's memory.
// The script is based on "Linkset Resizer" script by Maestro Linden.
// http://wiki.secondlife.com/wiki/Linkset_resizer
// This script still doesn't check prim linkability rules, which are described in:
// http://wiki.secondlife.com/wiki/Linkability_Rules
// Special thanks to:
// Ann Otoole
// Changed  float MIN_DIMENSION=0.01 to 0.001 - Taarna Welles 2013
 
float MIN_DIMENSION=0.001; // the minimum scale of a prim allowed, in any dimension (OpenSim Only)
float MAX_DIMENSION=10.0; // the maximum scale of a prim allowed, in any dimension
 
float max_scale;
float min_scale;

float   cur_scale = 1.0;
integer handle;
integer menuChan;

integer showDebugMessages = FALSE;
integer shown = TRUE;
 
float min_original_scale=10.0; // minimum x/y/z component of the scales in the linkset
float max_original_scale=0.0; // minimum x/y/z component of the scales in the linkset
 
list link_scales = [];
list link_positions = [];

debug(string text) {
    if(! showDebugMessages) return;
    llOwnerSay("/me debug: " + text);
}

makeMenu()
{
    llListenRemove(handle);
    menuChan = 50000 + (integer)llFrand(50000.00);
    handle = llListen(menuChan,"",llGetOwner(),"");
 
    //the button values can be changed i.e. you can set a value like "-1.00" or "+2.00"
    //and it will work without changing anything else in the script
    list buttons;
    if(shown) {
        buttons=[
            "-0.05","-0.10","-0.25",
            "+0.05","+0.10","+0.25",
            "MIN SIZE","RESTORE","MAX SIZE",
            "Hide", "Delete Script"
        ];
    } else {
        buttons=["Show"]; 
    }
    llDialog(llGetOwner(),"Max scale: "+(string)max_scale+"\nMin scale: "+(string)min_scale+"\n \nCurrent scale: "+
        (string)cur_scale,buttons,menuChan);
}
 
integer scanLinkset()
{
    integer link_qty = llGetNumberOfPrims();
    integer link_idx;
    vector link_pos;
    vector link_scale;

    link_scales = [];
    link_positions = [];
 
    //script made specifically for linksets, not for single prims
    if (link_qty > 1)
    {
        //link numbering in linksets starts with 1
        for (link_idx=1; link_idx <= link_qty; link_idx++)
        {
            // We use PRIM_POS_LOCAL instead of PRIM_POSITION, to avoid broken 
            // positions when resetting the script while the object is worn.
            link_pos=llList2Vector(llGetLinkPrimitiveParams(link_idx,[PRIM_POS_LOCAL]),0);
            link_scale=llList2Vector(llGetLinkPrimitiveParams(link_idx,[PRIM_SIZE]),0);
 
            // determine the minimum and maximum prim scales in the linkset,
            // so that rescaling doesn't fail due to prim scale limitations
            if(link_scale.x<min_original_scale) min_original_scale=link_scale.x;
            else if(link_scale.x>max_original_scale) max_original_scale=link_scale.x;
            if(link_scale.y<min_original_scale) min_original_scale=link_scale.y;
            else if(link_scale.y>max_original_scale) max_original_scale=link_scale.y;
            if(link_scale.z<min_original_scale) min_original_scale=link_scale.z;
            else if(link_scale.z>max_original_scale) max_original_scale=link_scale.z;
 
            link_scales    += [link_scale];
            link_positions += [link_pos];
        }
    }
    else
    {
        llOwnerSay("error: this script doesn't work for non-linked objects");
        return FALSE;
    }
 
    max_scale = MAX_DIMENSION/max_original_scale;
    min_scale = MIN_DIMENSION/min_original_scale;
 
    return TRUE;
}
 
resizeObject(float scale)
{
    integer link_qty = llGetNumberOfPrims();
    integer link_idx;
    vector new_size;
    vector new_pos;
 
    if (link_qty > 1)
    {
        //link numbering in linksets starts with 1
        for (link_idx=1; link_idx <= link_qty; link_idx++)
        {
            if(shown) {
                new_size   = scale * llList2Vector(link_scales, link_idx-1);
                new_pos    = scale * llList2Vector(link_positions, link_idx-1);
            } else {
                new_size   = <MIN_DIMENSION,MIN_DIMENSION,MIN_DIMENSION>;
                new_pos    = <0,0,0>;
            }
            if (link_idx == 1)
            {
                //because we don't really want to move the root prim as it moves the whole object
                llSetLinkPrimitiveParamsFast(link_idx, [PRIM_SIZE, new_size]);
            }
            else
            {
                llSetLinkPrimitiveParamsFast(link_idx, [PRIM_SIZE, new_size, PRIM_POSITION, new_pos]);
            }
        }
    }
}
 
default
{
    state_entry()
    {
        if (scanLinkset())
        {
            //debug("resizer script ready");
        }
        else
        {
            llOwnerSay("Script will be deleted from the prim");
            llRemoveInventory(llGetScriptName());
        }
    }

    touch_start(integer total)
    {
        if (llDetectedKey(0) == llGetOwner()) makeMenu();
    }
 
    listen(integer channel, string name, key id, string msg)
    {
        //you can never be too secure
        if (id == llGetOwner())
        {
            if (msg == "RESTORE")
            {
                cur_scale = 1.0;
            }
            else if (msg == "MIN SIZE")
            {
                cur_scale = min_scale;
            }
            else if (msg == "MAX SIZE")
            {
                cur_scale = max_scale;
            }
            else if (msg == "Hide")
            {
                shown = FALSE;
                makeMenu();
            }
            else if (msg == "Show")
            {
                shown = TRUE;
            }
            else if (msg == "Delete script")
            {                
                           llDialog(llGetOwner(),"Are you sure you want to delete the resizer script?", 
                           ["DELETE","CANCEL"],menuChan);
                           return;                
            }                
            else if (msg == "Delete Script")
            {                
               llOwnerSay("deleting " + llGetScriptName() + " script...");
               llRemoveInventory(llGetScriptName());                
            }            
            else
            {
                cur_scale += (float)msg;
            }
 
            //check that the scale doesn't go beyond the bounds
            if (cur_scale > max_scale) { cur_scale = max_scale; }
            if (cur_scale < min_scale) { cur_scale = min_scale; }
 
            resizeObject(cur_scale);
        }
    }
}