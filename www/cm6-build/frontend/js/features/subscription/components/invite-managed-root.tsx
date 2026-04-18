import { JSXElementConstructor } from 'react'
const importOverleafModules = () => [];

const [inviteManagedModule] = importOverleafModules(
  'managedGroupEnrollmentInvite'
)
const InviteManaged: JSXElementConstructor<Record<string, never>> =
  inviteManagedModule?.import.default

export default function InviteManagedRoot() {
  return <InviteManaged />
}
