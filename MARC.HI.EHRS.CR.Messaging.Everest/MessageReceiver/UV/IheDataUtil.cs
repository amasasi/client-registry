﻿/**
 * Copyright 2013-2013 Mohawk College of Applied Arts and Technology
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
 * Date: 6-2-2013
 */

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;
using MARC.HI.EHRS.SVC.Core.DataTypes;
using MARC.Everest.Connectors;
using MARC.HI.EHRS.SVC.Core.Issues;
using System.Data.Common;
using MARC.HI.EHRS.SVC.Core.Exceptions;
using MARC.HI.EHRS.CR.Core.ComponentModel;
using MARC.Everest.Connectors.WCF;
using System.Net;
using MARC.HI.EHRS.SVC.Core.ComponentModel.Components;
using MARC.Everest.RMIM.UV.NE2008.Interactions;
using MARC.Everest.Interfaces;
using MARC.Everest.Formatters.XML.ITS1;
using MARC.Everest.Formatters.XML.Datatypes.R1;
using System.IO;
using MARC.Everest.Xml;
using System.Xml;
using MARC.HI.EHRS.SVC.Core.ComponentModel;
using System.Diagnostics;
using System.ServiceModel;

namespace MARC.HI.EHRS.CR.Messaging.Everest.MessageReceiver.UV
{
    /// <summary>
    /// Data utility class specifically for IHE PIX transaction(s)
    /// </summary>
    public class IheDataUtil : DataUtil
    {

        /// <summary>
        /// Create audit data that is in response to a query
        /// </summary>
        internal AuditData CreateAuditData(string itiName, ActionType actionType, OutcomeIndicator outcomeIndicator, UnsolicitedDataEventArgs msgEvent, IReceiveResult msgReceiveResult, QueryResultData result, HealthcareParticipant author)
        {

            // Create the call to the other create audit data message by constructing the list of disclosed identifiers
            List<VersionedDomainIdentifier> vids = new List<VersionedDomainIdentifier>(result.Results.Length);
            foreach (var res in result.Results)
            {
                if (res == null) continue;
                var subj = res.FindComponent(SVC.Core.ComponentModel.HealthServiceRecordSiteRoleType.SubjectOf) as Person;
                if (subj == null)
                    continue;
                vids.Add(new VersionedDomainIdentifier()
                {
                    Domain = this.m_configService.OidRegistrar.GetOid("CR_CID").Oid,
                    Identifier = subj.Id.ToString()
                });
            }

            return CreateAuditData(itiName, actionType, outcomeIndicator, msgEvent, msgReceiveResult, vids, author);
        }

        /// <summary>
        /// Create audit data
        /// </summary>
        public AuditData CreateAuditData(string itiName, ActionType action, OutcomeIndicator outcome, UnsolicitedDataEventArgs msgEvent, IReceiveResult msgReceiveResult, IEnumerable<VersionedDomainIdentifier> patientRecord, HealthcareParticipant author)
        {
            // Audit data
            AuditData retVal = null;

            AuditableObjectLifecycle lifecycle = AuditableObjectLifecycle.Access;
            var wcfReceiveResult = msgReceiveResult as WcfReceiveResult;
            var msgReplyTo = wcfReceiveResult == null || wcfReceiveResult.Headers == null || wcfReceiveResult.Headers.ReplyTo == null ? msgEvent.SolicitorEndpoint.ToString() : wcfReceiveResult.Headers.ReplyTo.Uri.ToString();

            string userId = String.Empty;
            if (OperationContext.Current.Channel.RemoteAddress != null && OperationContext.Current.Channel.RemoteAddress.Uri != null)
                userId = OperationContext.Current.Channel.RemoteAddress.Uri.OriginalString;
            else if (OperationContext.Current.ServiceSecurityContext != null && OperationContext.Current.ServiceSecurityContext.PrimaryIdentity != null)
                userId = OperationContext.Current.ServiceSecurityContext.PrimaryIdentity.Name;


            switch (itiName)
            {
                case "PRPA_TE101103CA":
                    {
                        retVal = new AuditData(DateTime.Now, action, outcome, EventIdentifierType.PatientRecord, new CodeValue(itiName, "HL7 Trigger Events"));

                        // Audit actor for Patient Identity Source
                        retVal.Actors.Add(new AuditActorData()
                        {
                            UserIsRequestor = true,
                            UserIdentifier = msgReplyTo,
                            ActorRoleCode = new List<CodeValue>() {
                            new  CodeValue("110153", "DCM") { DisplayName = "Source" }
                        },
                            NetworkAccessPointId = msgEvent.SolicitorEndpoint.Host,
                            NetworkAccessPointType = msgEvent.SolicitorEndpoint.HostNameType == UriHostNameType.Dns ? NetworkAccessPointType.MachineName : NetworkAccessPointType.IPAddress,
                            UserName = userId
                        });
                        // Audit actor for PIX manager
                        retVal.Actors.Add(new AuditActorData()
                        {
                            UserIdentifier = msgEvent.ReceiveEndpoint.ToString(),
                            UserIsRequestor = false,
                            ActorRoleCode = new List<CodeValue>() { new CodeValue("110152", "DCM") { DisplayName = "Destination" } },
                            NetworkAccessPointType = NetworkAccessPointType.MachineName,
                            NetworkAccessPointId = Dns.GetHostName(),
                            AlternativeUserId = Process.GetCurrentProcess().Id.ToString()
                        });


                        var request = msgReceiveResult.Structure as MARC.Everest.RMIM.CA.R020402.Interactions.PRPA_IN101103CA;
                        retVal.AuditableObjects.Add(new AuditableObject()
                        {
                            Type = AuditableObjectType.SystemObject,
                            Role = AuditableObjectRole.Query,
                            IDTypeCode = AuditableObjectIdType.SearchCritereon,
                            QueryData = Convert.ToBase64String(SerializeQuery(request.controlActEvent.QueryByParameter)),
                            ObjectId = String.Format("{1}^^^&{0}&ISO", request.controlActEvent.QueryByParameter.QueryId.Root, request.controlActEvent.QueryByParameter.QueryId.Extension)
                        });

                        break;
                    }
                case "PRPA_TE101101CA":
                    {
                        retVal = new AuditData(DateTime.Now, action, outcome, EventIdentifierType.PatientRecord, new CodeValue(itiName, "HL7 Trigger Events"));

                        // Audit actor for Patient Identity Source
                        retVal.Actors.Add(new AuditActorData()
                        {
                            UserIsRequestor = true,
                            UserIdentifier = msgReplyTo,
                            ActorRoleCode = new List<CodeValue>() {
                            new  CodeValue("110153", "DCM") { DisplayName = "Source" }
                        },
                            NetworkAccessPointId = msgEvent.SolicitorEndpoint.Host,
                            NetworkAccessPointType = msgEvent.SolicitorEndpoint.HostNameType == UriHostNameType.Dns ? NetworkAccessPointType.MachineName : NetworkAccessPointType.IPAddress,
                            UserName = userId
                        });
                        // Audit actor for PIX manager
                        retVal.Actors.Add(new AuditActorData()
                        {
                            UserIdentifier = msgEvent.ReceiveEndpoint.ToString(),
                            UserIsRequestor = false,
                            ActorRoleCode = new List<CodeValue>() { new CodeValue("110152", "DCM") { DisplayName = "Destination" } },
                            NetworkAccessPointType = NetworkAccessPointType.MachineName,
                            NetworkAccessPointId = Dns.GetHostName(),
                            AlternativeUserId = Process.GetCurrentProcess().Id.ToString()
                        });


                        var request = msgReceiveResult.Structure as MARC.Everest.RMIM.CA.R020402.Interactions.PRPA_IN101101CA;
                        retVal.AuditableObjects.Add(new AuditableObject()
                        {
                            Type = AuditableObjectType.SystemObject,
                            Role = AuditableObjectRole.Query,
                            IDTypeCode = AuditableObjectIdType.SearchCritereon,
                            QueryData = Convert.ToBase64String(SerializeQuery(request.controlActEvent.QueryByParameter)),
                            ObjectId = String.Format("{1}^^^&{0}&ISO", request.controlActEvent.QueryByParameter.QueryId.Root, request.controlActEvent.QueryByParameter.QueryId.Extension)
                        });

                        break;
                    }

                case "PRPA_TE101105CA":
                    {
                        retVal = new AuditData(DateTime.Now, action, outcome, EventIdentifierType.PatientRecord, new CodeValue(itiName, "HL7 Trigger Events"));

                        // Audit actor for Patient Identity Source
                        retVal.Actors.Add(new AuditActorData()
                        {
                            UserIsRequestor = true,
                            UserIdentifier = msgReplyTo,
                            ActorRoleCode = new List<CodeValue>() {
                            new  CodeValue("110153", "DCM") { DisplayName = "Source" }
                        },
                            NetworkAccessPointId = msgEvent.SolicitorEndpoint.Host,
                            NetworkAccessPointType = msgEvent.SolicitorEndpoint.HostNameType == UriHostNameType.Dns ? NetworkAccessPointType.MachineName : NetworkAccessPointType.IPAddress,
                            UserName = userId
                        });
                        // Audit actor for PIX manager
                        retVal.Actors.Add(new AuditActorData()
                        {
                            UserIdentifier = msgEvent.ReceiveEndpoint.ToString(),
                            UserIsRequestor = false,
                            ActorRoleCode = new List<CodeValue>() { new CodeValue("110152", "DCM") { DisplayName = "Destination" } },
                            NetworkAccessPointType = NetworkAccessPointType.MachineName,
                            NetworkAccessPointId = Dns.GetHostName(),
                            AlternativeUserId = Process.GetCurrentProcess().Id.ToString()
                        });


                        var request = msgReceiveResult.Structure as MARC.Everest.RMIM.CA.R020402.Interactions.PRPA_IN101105CA;
                        retVal.AuditableObjects.Add(new AuditableObject()
                        {
                            Type = AuditableObjectType.SystemObject,
                            Role = AuditableObjectRole.Query,
                            IDTypeCode = AuditableObjectIdType.SearchCritereon,
                            QueryData = Convert.ToBase64String(SerializeQuery(request.controlActEvent.QueryByParameter)),
                            ObjectId = String.Format("{1}^^^&{0}&ISO", request.controlActEvent.QueryByParameter.QueryId.Root, request.controlActEvent.QueryByParameter.QueryId.Extension)
                        });

                        break;

                        break;
                    }
                case "ITI-44":
                    retVal = new AuditData(DateTime.Now, action, outcome, EventIdentifierType.PatientRecord, new CodeValue(itiName, "IHE Transactions"));

                    // Audit actor for Patient Identity Source
                    retVal.Actors.Add( new AuditActorData() {
                        UserIsRequestor = true, 
                        UserIdentifier = msgReplyTo,
                        ActorRoleCode = new List<CodeValue>() {
                            new  CodeValue("110153", "DCM") { DisplayName = "Source" }
                        }, 
                        NetworkAccessPointId = msgEvent.SolicitorEndpoint.Host,
                        NetworkAccessPointType = msgEvent.SolicitorEndpoint.HostNameType == UriHostNameType.Dns ? NetworkAccessPointType.MachineName : NetworkAccessPointType.IPAddress,
                        UserName = userId
                    });
                    // Audit actor for PIX manager
                    retVal.Actors.Add(new AuditActorData()
                    {
                        UserIdentifier = msgEvent.ReceiveEndpoint.ToString(),
                        UserIsRequestor = false,
                        ActorRoleCode = new List<CodeValue>() { new CodeValue("110152", "DCM") { DisplayName = "Destination" } },
                        NetworkAccessPointType = NetworkAccessPointType.MachineName,
                        NetworkAccessPointId = Dns.GetHostName(),
                        AlternativeUserId = Process.GetCurrentProcess().Id.ToString()
                    });
                    break;
                case "ITI-45":
                    {
                        retVal = new AuditData(DateTime.Now, ActionType.Execute, outcome, EventIdentifierType.Query, new CodeValue("ITI-45", "IHE Transactions") { DisplayName = "PIX Query" });
                        // Audit actor for Patient Identity Source
                        retVal.Actors.Add(new AuditActorData()
                        {
                            UserIsRequestor = true,
                            UserIdentifier = msgReplyTo,
                            ActorRoleCode = new List<CodeValue>() {
                            new  CodeValue("110153", "DCM") { DisplayName = "Source" }
                        },
                            NetworkAccessPointId = msgEvent.SolicitorEndpoint.Host,
                            NetworkAccessPointType = msgEvent.SolicitorEndpoint.HostNameType == UriHostNameType.Dns ? NetworkAccessPointType.MachineName : NetworkAccessPointType.IPAddress,
                            UserName = userId
                        });
                        // Audit actor for PIX manager
                        retVal.Actors.Add(new AuditActorData()
                        {
                            UserIdentifier = msgEvent.ReceiveEndpoint.ToString(),
                            UserIsRequestor = false,
                            ActorRoleCode = new List<CodeValue>() { new CodeValue("110152", "DCM") { DisplayName = "Destination" } },
                            NetworkAccessPointType = NetworkAccessPointType.MachineName,
                            NetworkAccessPointId = Dns.GetHostName(),
                            AlternativeUserId = Process.GetCurrentProcess().Id.ToString()
                        });

                        // Add query 
                        var request = msgReceiveResult.Structure as PRPA_IN201309UV02;

                        retVal.AuditableObjects.Add(new AuditableObject()
                        {
                            Type = AuditableObjectType.SystemObject,
                            Role = AuditableObjectRole.Query,
                            IDTypeCode = AuditableObjectIdType.Custom,
                            CustomIdTypeCode = new CodeValue("ITI45", "IHE Transactions"),
                            QueryData = Convert.ToBase64String(SerializeQuery(request.controlActProcess.queryByParameter)),
                            ObjectId = String.Format("{1}^^^&{0}&ISO", request.controlActProcess.queryByParameter.QueryId.Root, request.controlActProcess.queryByParameter.QueryId.Extension)
                        });

                        break;
                    }
                case "ITI-47":
                    {
                        retVal = new AuditData(DateTime.Now, ActionType.Execute, outcome, EventIdentifierType.Query, new CodeValue("ITI-47", "IHE Transactions") { DisplayName = "Patient Demographics Query" });
                        // Audit actor for Patient Identity Source
                        retVal.Actors.Add(new AuditActorData()
                        {
                            UserIsRequestor = true,
                            UserIdentifier = msgReplyTo,
                            ActorRoleCode = new List<CodeValue>() {
                            new  CodeValue("110153", "DCM") { DisplayName = "Source" }
                        },
                            NetworkAccessPointId = msgEvent.SolicitorEndpoint.Host,
                            NetworkAccessPointType = msgEvent.SolicitorEndpoint.HostNameType == UriHostNameType.Dns ? NetworkAccessPointType.MachineName : NetworkAccessPointType.IPAddress,
                            UserName = userId
                        });
                        // Audit actor for PIX manager
                        retVal.Actors.Add(new AuditActorData()
                        {
                            UserIdentifier = msgEvent.ReceiveEndpoint.ToString(),
                            UserIsRequestor = false,
                            ActorRoleCode = new List<CodeValue>() { new CodeValue("110152", "DCM") { DisplayName = "Destination" } },
                            NetworkAccessPointType = NetworkAccessPointType.MachineName,
                            NetworkAccessPointId = Dns.GetHostName(),
                            AlternativeUserId = Process.GetCurrentProcess().Id.ToString()
                        });

                        // Add query 
                        var request = msgReceiveResult.Structure as PRPA_IN201305UV02;

                        retVal.AuditableObjects.Add(new AuditableObject()
                        {
                            Type = AuditableObjectType.SystemObject,
                            Role = AuditableObjectRole.Query,
                            IDTypeCode = AuditableObjectIdType.Custom,
                            CustomIdTypeCode = new CodeValue("ITI47", "IHE Transactions"),
                            QueryData = Convert.ToBase64String(SerializeQuery(request.controlActProcess.queryByParameter)),
                            ObjectId = String.Format("{1}^^^&{0}&ISO", request.controlActProcess.queryByParameter.QueryId.Root, request.controlActProcess.queryByParameter.QueryId.Extension)
                        });

                        break;
                    }
            }

            // Audit authors
            if (author != null)
            {
                retVal.AuditableObjects.Add(new AuditableObject()
                {
                    IDTypeCode = AuditableObjectIdType.UserIdentifier,
                    ObjectId = String.Format("{1}^^^&{0}&ISO", m_configService.OidRegistrar.GetOid("CR_PID"), author.Id),
                    Role = AuditableObjectRole.Provider,
                    Type = AuditableObjectType.Person,
                    LifecycleType = (AuditableObjectLifecycle?)(action == ActionType.Read ? (object)AuditableObjectLifecycle.ReceiptOfDisclosure : null)
                });

            }
            // Audit patients
            foreach (var pat in patientRecord)
            {
                // Construct the audit object
                AuditableObject aud = new AuditableObject()
                {
                    IDTypeCode = AuditableObjectIdType.PatientNumber,
                    Role = AuditableObjectRole.Patient,
                    Type = AuditableObjectType.Person
                };
                
                // Lifecycle
                switch (action)
                {
                    case ActionType.Create:
                        aud.LifecycleType = AuditableObjectLifecycle.Creation;
                        break;
                    case ActionType.Delete:
                        aud.LifecycleType = AuditableObjectLifecycle.LogicalDeletion;
                        break;
                    case ActionType.Execute:
                        aud.LifecycleType = AuditableObjectLifecycle.Access;
                        break;
                    case ActionType.Read:
                        aud.LifecycleType = AuditableObjectLifecycle.Disclosure;
                        break;
                    case ActionType.Update:
                        aud.LifecycleType = AuditableObjectLifecycle.Amendment;
                        break;
                }

                aud.ObjectId = String.Format("{1}^^^&{0}&ISO", pat.Domain, pat.Identifier);
                retVal.AuditableObjects.Add(aud);

            }
            return retVal;
        }

        /// <summary>
        /// Serialize query 
        /// </summary>
        internal static byte[] SerializeQuery(IGraphable queryByParameter)
        {
            using (XmlIts1Formatter fmtr = new XmlIts1Formatter() { ValidateConformance = false })
            {
                StringBuilder sb = new StringBuilder();
                XmlStateWriter writer = new XmlStateWriter(XmlWriter.Create(sb));

                // Write the start element
                writer.WriteStartElement("queryByParameter", "urn:hl7-org:v3");
                fmtr.GraphAides.Add(new DatatypeFormatter() { CompatibilityMode = DatatypeFormatterCompatibilityMode.Universal, ValidateConformance = false });
                fmtr.Graph(writer, queryByParameter);
                writer.WriteEndElement();
                writer.Close();

                // Return the constructed result
                return Encoding.ASCII.GetBytes(sb.ToString());
            }
        }

        /// <summary>
        /// Register a client in the registry
        /// </summary>
        internal override SVC.Core.DataTypes.VersionedDomainIdentifier Register(Core.ComponentModel.RegistrationEvent healthServiceRecord, List<MARC.Everest.Connectors.IResultDetail> dtls, List<SVC.Core.Issues.DetectedIssue> issues, SVC.Core.Services.DataPersistenceMode mode)
        {

            try
            {

                // Can't find persistence
                if (this.m_persistenceService == null)
                {
                    dtls.Add(new PersistenceResultDetail(ResultDetailType.Error, "Couldn't locate an implementation of a PersistenceService object, storage is aborted", null));
                    return null;
                }
                else if (healthServiceRecord == null)
                {
                    dtls.Add(new PersistenceResultDetail(ResultDetailType.Error, "Can't register null health service record data", null));
                    return null;
                }
                else if (dtls.Count(o => o.Type == ResultDetailType.Error) > 0)
                {
                    dtls.Add(new PersistenceResultDetail(ResultDetailType.Error, "Won't attempt to persist invalid message", null));
                    return null;
                }
                                    

                // Call the dss
                if (this.m_decisionService != null)
                    issues.AddRange(this.m_decisionService.RecordPersisting(healthServiceRecord));

                // Any errors?
                if (issues.Count(o => o.Priority == IssuePriorityType.Error) > 0)
                    dtls.Add(new PersistenceResultDetail(ResultDetailType.Error, "Won't attempt to persist message due to detected issues", null));

                // Persist
                var retVal = this.m_persistenceService.StoreContainer(healthServiceRecord, mode);
                retVal.UpdateMode = UpdateModeType.Add;
                             

                // Call the dss
                if (this.m_decisionService != null)
                    this.m_decisionService.RecordPersisted(healthServiceRecord);

                // Call sub
                if (this.m_subscriptionService != null)
                    this.m_subscriptionService.PublishContainer(healthServiceRecord);

                // Register the document set if it is a document
                if (retVal != null && this.m_docRegService != null && !this.m_docRegService.RegisterRecord(healthServiceRecord, mode))
                    dtls.Add(new PersistenceResultDetail(ResultDetailType.Warning, "Wasn't able to register event in the event registry, event exists in repository but not in registry. You may not be able to query for this event", null));

                return retVal;
            }
            catch (DuplicateNameException ex) // Already persisted stuff
            {
                Trace.TraceError(ex.ToString());
                dtls.Add(new PersistenceResultDetail(ResultDetailType.Error, m_localeService.GetString("DTPE005"), ex));
                issues.Add(new DetectedIssue()
                {
                    Severity = IssueSeverityType.High,
                    Type = IssueType.AlreadyPerformed,
                    Text = ex.Message,
                    Priority = IssuePriorityType.Error
                });
                return null;
            }
            catch (MissingPrimaryKeyException ex) // Already persisted stuff
            {
                Trace.TraceError(ex.ToString());
                dtls.Add(new PersistenceResultDetail(ResultDetailType.Error, m_localeService.GetString("DTPE005"), ex));
                issues.Add(new DetectedIssue()
                {
                    Severity = IssueSeverityType.High,
                    Type = IssueType.DetectedIssue,
                    Text = ex.Message,
                    Priority = IssuePriorityType.Error
                });
                return null;
            }
            catch (ConstraintException ex)
            {
                Trace.TraceError(ex.ToString());
                dtls.Add(new PersistenceResultDetail(ResultDetailType.Error, m_localeService.GetString("DTPE005"), ex));
                issues.Add(new DetectedIssue()
                {
                    Severity = IssueSeverityType.High,
                    Type = IssueType.DetectedIssue,
                    Text = ex.Message,
                    Priority = IssuePriorityType.Error
                });
                return null;
            }
            catch (IssueException ex)
            {
                Trace.TraceError(ex.ToString());
                issues.Add(ex.Issue);
                return null;
            }
            catch (Exception ex)
            {
                Trace.TraceError(ex.ToString());
                dtls.Add(new ResultDetail(ResultDetailType.Error, ex.Message, ex));
                return null;
            }
        }

        /// <summary>
        /// Update the version identifier
        /// </summary>
        internal override VersionedDomainIdentifier Update(RegistrationEvent healthServiceRecord, List<IResultDetail> dtls, List<DetectedIssue> issues, SVC.Core.Services.DataPersistenceMode mode)
        {
            try
            {

                // Can't find persistence
                if (this.m_persistenceService == null)
                {
                    dtls.Add(new PersistenceResultDetail(ResultDetailType.Error, "Couldn't locate an implementation of a PersistenceService object, storage is aborted", null));
                    return null;
                }
                else if (healthServiceRecord == null)
                {
                    dtls.Add(new PersistenceResultDetail(ResultDetailType.Error, "Can't register null health service record data", null));
                    return null;
                }
                else if (dtls.Count(o => o.Type == ResultDetailType.Error) > 0)
                {
                    dtls.Add(new PersistenceResultDetail(ResultDetailType.Error, "Won't attempt to persist invalid message", null));
                    return null;
                }
                
                // Call the dss
                if (this.m_decisionService != null)
                    issues.AddRange(this.m_decisionService.RecordPersisting(healthServiceRecord));

                // Any errors?
                if (issues.Count(o => o.Priority == IssuePriorityType.Error) > 0)
                    dtls.Add(new PersistenceResultDetail(ResultDetailType.Error, "Won't attempt to persist message due to detected issues", null));

                // Persist
                var retVal = this.m_persistenceService.UpdateContainer(healthServiceRecord, mode);

                retVal.UpdateMode = UpdateModeType.Update;

                // Call the dss
                if (this.m_decisionService != null)
                    this.m_decisionService.RecordPersisted(healthServiceRecord);

                // Call sub
                if (this.m_subscriptionService != null)
                    this.m_subscriptionService.PublishContainer(healthServiceRecord);

                // Register the document set if it is a document
                if (retVal != null && this.m_docRegService != null && !this.m_docRegService.RegisterRecord(healthServiceRecord, mode))
                    dtls.Add(new PersistenceResultDetail(ResultDetailType.Warning, "Wasn't able to register event in the event registry, event exists in repository but not in registry. You may not be able to query for this event", null));

                return retVal;
            }
            catch (DuplicateNameException ex) // Already persisted stuff
            {
                Trace.TraceError(ex.ToString());
                dtls.Add(new PersistenceResultDetail(ResultDetailType.Error, m_localeService.GetString("DTPE005"), ex));
                issues.Add(new DetectedIssue()
                {
                    Severity = IssueSeverityType.High,
                    Type = IssueType.AlreadyPerformed,
                    Text = ex.Message,
                    Priority = IssuePriorityType.Error
                });
                return null;
            }
            catch (MissingPrimaryKeyException ex) // Already persisted stuff
            {
                Trace.TraceError(ex.ToString());
                dtls.Add(new PersistenceResultDetail(ResultDetailType.Error, m_localeService.GetString("DTPE005"), ex));
                issues.Add(new DetectedIssue()
                {
                    Severity = IssueSeverityType.High,
                    Type = IssueType.DetectedIssue,
                    Text = ex.Message,
                    Priority = IssuePriorityType.Error
                });
                return null;
            }
            catch (ConstraintException ex)
            {
                Trace.TraceError(ex.ToString());
                dtls.Add(new PersistenceResultDetail(ResultDetailType.Error, m_localeService.GetString("DTPE005"), ex));
                issues.Add(new DetectedIssue()
                {
                    Severity = IssueSeverityType.High,
                    Type = IssueType.DetectedIssue,
                    Text = ex.Message,
                    Priority = IssuePriorityType.Error
                });
                return null;
            }
            catch (IssueException ex)
            {
                Trace.TraceError(ex.ToString());
                issues.Add(ex.Issue);
                return null;
            }
            catch (Exception ex)
            {
                Trace.TraceError(ex.ToString());
                dtls.Add(new ResultDetail(ResultDetailType.Error, ex.Message, ex));
                return null;
            }
        }

        /// <summary>
        /// Validate identifiers
        /// </summary>
        internal bool ValidateIdentifiers(RegistrationEvent data, List<IResultDetail> dtls)
        {
            Person subject = data.FindComponent(SVC.Core.ComponentModel.HealthServiceRecordSiteRoleType.SubjectOf) as Person;
            //var scoper = subject.FindComponent(SVC.Core.ComponentModel.HealthServiceRecordSiteRoleType.PlaceOfEntry | SVC.Core.ComponentModel.HealthServiceRecordSiteRoleType.InformantTo) as HealthcareParticipant;
            //var custodian = data.FindComponent(SVC.Core.ComponentModel.HealthServiceRecordSiteRoleType.PlaceOfRecord | SVC.Core.ComponentModel.HealthServiceRecordSiteRoleType.ResponsibleFor);

            bool isValid = true;
            //// Validate the root
            //foreach (var id in subject.AlternateIdentifiers)
            //    if (scoper != null && !scoper.AlternateIdentifiers.Exists(o => o.Domain == id.Domain))
            //    {
            //        isValid = false;
            //        dtls.Add(new FormalConstraintViolationResultDetail(ResultDetailType.Error, this.m_localeService.GetString("MSGW015"), null, null));
            //    }
            //    else if (scoper != null && String.IsNullOrEmpty(id.AssigningAuthority))
            //        id.AssigningAuthority = scoper.LegalName.Parts[0].Value;
            //    else if (String.IsNullOrEmpty(id.AssigningAuthority) && custodian is RepositoryDevice && (custodian as RepositoryDevice).AlternateIdentifier.Domain == id.Domain)
            //        id.AssigningAuthority = (custodian as RepositoryDevice).Name;
            //    else if (String.IsNullOrEmpty(id.AssigningAuthority) && custodian is HealthcareParticipant && (custodian as HealthcareParticipant).AlternateIdentifiers.Exists(o => o.Domain == id.Domain))
            //        id.AssigningAuthority = (custodian as HealthcareParticipant).LegalName.Parts[0].Value;


            // Validate we know all identifiers
            foreach (var id in subject.AlternateIdentifiers)
            {
                if (String.IsNullOrEmpty(id.AssigningAuthority))
                {
                    dtls.Add(new FormalConstraintViolationResultDetail(ResultDetailType.Error, String.Format(m_localeService.GetString("MSGE06A"), id.Domain), null, null));
                    isValid = false;
                }
            }

            return isValid;
        }

        /// <summary>
        /// Override query method
        /// </summary>
        internal override QueryResultData Query(QueryData filter, List<IResultDetail> dtls, List<DetectedIssue> issues)
        {
            try
            {

                List<VersionedDomainIdentifier> retRecordId = new List<VersionedDomainIdentifier>(100);
                // Query continuation
                if (this.m_docRegService == null)
                    throw new InvalidOperationException("No record registration service is registered. Querying for records cannot be done unless this service is present");
                else if (this.m_queryService != null && this.m_queryService.IsRegistered(filter.QueryId.ToLower()))
                    throw new Exception(String.Format("The query '{0}' has already been registered. To continue this query use the QUQI_IN000003UV01 interaction", filter.QueryId));
                else
                {

                    // Query the document registry service
                    var queryFilter = filter.QueryRequest.FindComponent(HealthServiceRecordSiteRoleType.FilterOf); // The outer filter data is usually just parameter control..

                    var recordIds = this.m_docRegService.QueryRecord(queryFilter as HealthServiceRecordComponent);
                    if (recordIds.Length == 0 && filter.IsSummary)
                        dtls.Add(new PatientNotFoundResultDetail(this.m_localeService));

                    var retVal = GetRecordsAsync(recordIds, retRecordId, issues, dtls, filter);

                    // Sort control?
                    // TODO: Support sort control
                    //retVal.Sort((a, b) => b.Id.CompareTo(a.Id)); // Default sort by id

                    // Persist the query
                    if (this.m_queryService != null)
                    {
                        this.m_queryService.RegisterQuerySet(filter.QueryId.ToLower(), recordIds, filter);
                        this.m_queryService.GetQueryResults(filter.QueryId, -1, filter.Quantity);
                    }
                    // Return query data
                    return new QueryResultData()
                    {
                        QueryId = filter.QueryId.ToLower(),
                        Results = retVal.ToArray(),
                        TotalResults = retRecordId.Count(o => o != null)
                    };

                }

            }
            catch (TimeoutException ex)
            {
                dtls.Add(new PersistenceResultDetail(ResultDetailType.Error, ex.Message, ex));
                return QueryResultData.Empty;
            }
            catch (DbException ex)
            {
                dtls.Add(new PersistenceResultDetail(ResultDetailType.Error, ex.Message, ex));
                return QueryResultData.Empty;
            }
            catch (DataException ex)
            {
                dtls.Add(new PersistenceResultDetail(ResultDetailType.Error, ex.Message, ex));
                return QueryResultData.Empty;
            }
            catch (Exception ex)
            {
                dtls.Add(new ResultDetail(ResultDetailType.Error, ex.Message, ex));
                return QueryResultData.Empty;
            }
        }
    }
}
