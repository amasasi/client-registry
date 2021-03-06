﻿/**
 * Copyright 2012-2013 Mohawk College of Applied Arts and Technology
 * 
 * Licensed under the Apache License, Version 2.0 (the "License"); you 
 * may not use this file except in compliance with the License. You may 
 * obtain a copy of the License at 
 * 
 * http://www.apache.org/licenses/LICENSE-2.0 
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the 
 * License for the specific language governing permissions and limitations under 
 * the License.
 * 
 * User: fyfej
 * Date: 5-12-2012
 */

using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Data;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using MARC.HI.EHRS.SVC.Core.Configuration;
using System.Xml;
using System.Reflection;
using MARC.HI.EHRS.CR.Core.ComponentModel;

namespace MARC.HI.EHRS.CR.Configurator.SharedHealthCore.Panels
{
    public partial class pnlConfigureDatabase : UserControl
    {

        /// <summary>
        /// Match field struct
        /// </summary>
        public struct MatchField
        {
            /// <summary>
            /// GEts the key of the match field
            /// </summary>
            public string Key { get; set; }
            /// <summary>
            /// Gets the display name of the field
            /// </summary>
            public string Value { get; set; }
            /// <summary>
            /// Creates a new match field
            /// </summary>
            public MatchField(string key, string value) : this()
            {
                Key = key;
                Value = value;
            }
            public override string ToString()
            {
                return this.Value;
            }
            public override bool Equals(object obj)
            {
                if (obj is string)
                    return this.Key.Equals(obj.ToString());
                return base.Equals(obj);
            }
        }

        public pnlConfigureDatabase()
        {
            InitializeComponent();
            this.MatchFields = new List<string>();
            PopulateMergeFields();
        }

        /// <summary>
        /// Merge fields
        /// </summary>
        private void PopulateMergeFields()
        {
            lstMerge.Items.Clear();
            foreach (PropertyInfo pi in typeof(Person).GetProperties(BindingFlags.Public | BindingFlags.Instance))
            {
                object[] da = pi.GetCustomAttributes(typeof(DescriptionAttribute), false);
                if (da.Length == 0) continue;
                lstMerge.Items.Add(new MatchField(pi.Name, (da[0] as DescriptionAttribute).Description));
            }
        }

      
        /// <summary>
        /// Database connector
        /// </summary>
        public IDatabaseConfigurator DatabaseConfigurator 
        {
            get { return this.dbSelector.DatabaseConfigurator; }
            set { this.dbSelector.DatabaseConfigurator = value; }
        }

        /// <summary>
        /// Get connection string
        /// </summary>
        public string GetConnectionString(XmlDocument configurationDom)
        {
            return this.dbSelector.GetConnectionString(configurationDom);
        }

        /// <summary>
        /// Set connection string stuff
        /// </summary>
        public void SetConnectionString(XmlDocument configurationDom, string connectionString)
        {
            this.dbSelector.SetConnectionString(configurationDom, connectionString);
        }

       

        /// <summary>
        /// Allowed match algorithms
        /// </summary>
        public List<String> MatchAlgorithms
        {
            get
            {
                List<String> match = new List<string>();
                if (chkSoundex.Checked)
                    match.Add("Soundex");
                if (chkExact.Checked)
                    match.Add("Exact");
                if (chkVariant.Checked)
                    match.Add("Variant");
                return match;
            }
            set
            {
                if (value == null)
                    return;

                chkSoundex.Checked = chkVariant.Checked = chkExact.Checked;

                foreach (var val in value)
                {
                    chkSoundex.Checked |= val == "Soundex";
                    chkVariant.Checked |= val == "Variant";
                    chkExact.Checked |= val == "Exact";
                }

            }
        }

        public String DefaultMatchStrength
        {
            get
            {
                if (dlStrength.SelectedItem == null)
                    return null;
                return dlStrength.SelectedItem.ToString();
            }
            set
            {
                dlStrength.SelectedItem = value;
            }
        }

        public bool AllowDuplicates
        {
            get { return chkAllowDuplicates.Checked; }
            set { chkAllowDuplicates.Checked = value; }
        }

        public bool UpdateIfExists
        {
            get { return chkUpdateIfExists.Checked; }
            set { chkUpdateIfExists.Checked = value; }
        }

        public bool AutoMerge
        {
            get { return chkMerge.Checked; }
            set { chkMerge.Checked = value; }
        }

        public decimal MinMatch
        {
            get { return numMinCriteria.Value; }
            set { numMinCriteria.Value = value; }
        }



        /// <summary>
        /// Match fields
        /// </summary>
        public List<String> MatchFields 
        {
            get
            {
                List<String> matchFields = new List<string>();
                foreach (MatchField itm in this.lstMerge.CheckedItems)
                    matchFields.Add(itm.Key);
                return matchFields;
            }
            set
            {
                try
                {
                   
                    if (value == null || value.Count == 0)
                        return;
                    lstMerge.ClearSelected();

                    foreach (var itm in value)
                        this.lstMerge.SetItemCheckState(this.lstMerge.Items.IndexOf(itm), CheckState.Checked);
                }
                catch { }
            }
        }

      
        private void lstMerge_SelectedIndexChanged(object sender, EventArgs e)
        {
            this.numMinCriteria.Maximum = this.lstMerge.CheckedItems.Count;
        }

      

    }
}
