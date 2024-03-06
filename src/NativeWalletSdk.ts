import { type TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';
import { type PermittedItemDocType } from './index';

export interface Spec extends TurboModule {
  createSoftPrivateKeyFromPem(algo: string, pem: string): Promise<string>;

  createMdocFromCbor(cborBase64: string): Promise<string>;

  createBleManager(): Promise<string>;

  bleSessionStartPresentMdoc(
    bleUuid: string,
    mdocUuid: string,
    privateKeyUuid: string,
    deviceEngagement: string
  ): Promise<void>;

  bleSessionSubmitNamespaces(
    bleUuid: string,
    permitted: PermittedItemDocType[]
  ): Promise<void>;

  bleSessionCancel(bleUuid: string): Promise<void>;

  allCredentials(): Promise<string[]>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('WalletSdk');
