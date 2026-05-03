import { FC, useCallback, useMemo, useState } from 'react';
import { Button, Form, Input, message, Modal } from 'antd';
import styles from './index.module.scss';
import useUserStore from '@/store/user-store';
import userIcon from '@/assets/imgs/personal-center/user.svg';
import copyIcon from '@/assets/imgs/personal-center/copy.svg';
import editIcon from '@/assets/imgs/personal-center/edit.svg';
import yesIcon from '@/assets/imgs/personal-center/yes.svg';
import noIcon from '@/assets/imgs/personal-center/no.svg';
import actIcon from '@/assets/imgs/personal-center/act.png';
import fireIcon from '@/assets/imgs/personal-center/fire.png';
import emptyIcon from '@/assets/imgs/common/empty-gray.png';
import { copyText } from '@/utils/spark-utils';
import UploadAvatar from '@/components/upload-avatar';
import { PostChatItem } from '@/types/chat';
import { changePassword, updateUserInfo } from '@/services/spark-common';
import { useNavigate } from 'react-router-dom';
import { deleteChatList } from '@/services/chat';
import { useTranslation } from 'react-i18next';

interface PersonalCenterProps {
  open: boolean;
  onCancel: () => void;
  mixedChatList: PostChatItem[];
  onRefreshData: () => void;
  onRefreshRecentData: () => void;
}

interface TabItem {
  tab: string;
}

const tabs: TabItem[] = [{ tab: 'Recent' }, { tab: 'Favorites' }];

const EmptyState: FC = () => (
  <div className={styles.emptyBox}>
    <img src={emptyIcon} alt="" />
  </div>
);

const TabsHeader: FC<{
  tabs: TabItem[];
  activeIndex: number;
  onTabChange: (index: number) => void;
}> = ({ tabs, activeIndex, onTabChange }) => (
  <div className={styles.tabs}>
    {tabs.map((item, index) => (
      <div
        key={item.tab}
        onClick={() => onTabChange(index)}
        className={activeIndex === index ? styles.tabActive : styles.tab}
      >
        {item.tab}
      </div>
    ))}
  </div>
);

const RecentUsedList: FC<{
  recentList: PostChatItem[];
  onItemClick: (item: PostChatItem) => void;
  onDeleteClick: (item: PostChatItem, e: React.MouseEvent) => void;
}> = ({ recentList, onItemClick, onDeleteClick }) => {
  const memoizedList = useMemo(() => recentList, [recentList]);

  if (!memoizedList?.length) {
    return <EmptyState />;
  }

  return (
    <>
      {memoizedList.map(item => (
        <div
          key={item.id}
          onClick={() => onItemClick(item)}
          className={styles.itemBox}
        >
          <div className={styles.itemHead}>
            <img className={styles.headImg} src={item.botAvatar} alt="" />
            <div title={item.botName} className={styles.headTitle}>
              {item.botName}
            </div>
          </div>
          <div title={item.botDesc} className={styles.headDesc}>
            {item.botDesc}
          </div>
          <div className={styles.itemInfo}>
            <img className={styles.actImg} src={actIcon} alt="" />
            <div className={styles.actText}>{item.creatorName || '@PaiFlow'}</div>
            <img className={styles.fireImg} src={fireIcon} alt="" />
            <div className={styles.fireText}>{item.hotNum || 0}</div>
          </div>
          <div
            onClick={e => onDeleteClick(item, e)}
            className={styles.delete}
          />
        </div>
      ))}
    </>
  );
};

const PersonalCenterHeader: FC = () => {
  const userInfo = useUserStore((state: any) => state.user);
  const [showInput, setShowInput] = useState(false);
  const [infoName, setInfoName] = useState(userInfo.nickname || userInfo.login);
  const [passwordOpen, setPasswordOpen] = useState(false);
  const [passwordLoading, setPasswordLoading] = useState(false);
  const [form] = Form.useForm();

  const handleSaveProfile = () => {
    updateUserInfo({
      nickname: infoName,
      avatar: userInfo.avatar,
    })
      .then(() => {
        message.success('Profile updated');
        useUserStore.setState({
          user: {
            ...userInfo,
            nickname: infoName,
          },
        });
        setShowInput(false);
      })
      .catch((err: any) => {
        message.error(err?.message || 'Update failed');
      });
  };

  const handleChangePassword = async (values: {
    oldPassword: string;
    newPassword: string;
    confirmPassword: string;
  }) => {
    setPasswordLoading(true);
    try {
      await changePassword(values);
      message.success('Password updated, please sign in again');
      form.resetFields();
      setPasswordOpen(false);
      useUserStore.getState().logOut();
      window.location.href = '/login';
    } catch (error: any) {
      message.error(error?.message || 'Password update failed');
    } finally {
      setPasswordLoading(false);
    }
  };

  return (
    <div className={styles.header}>
      <div>
        <UploadAvatar
          coverUrl={userInfo.avatar}
          setCoverUrl={url => {
            updateUserInfo({
              nickname: infoName,
              avatar: url,
            }).then(() => {
              message.success('Profile updated');
              useUserStore.setState({
                user: {
                  ...userInfo,
                  avatar: url,
                },
              });
            });
          }}
          flag={true}
        />
      </div>
      <div>
        <div className={styles.flexTitle}>
          {showInput ? (
            <>
              <Input
                value={infoName}
                placeholder="Nickname"
                showCount
                maxLength={20}
                onChange={e => setInfoName(e.target.value)}
              />
              <img
                onClick={() => {
                  setShowInput(false);
                  setInfoName(userInfo.nickname || userInfo.login);
                }}
                className={styles.noBotton}
                src={noIcon}
                alt=""
              />
              <img
                onClick={handleSaveProfile}
                className={styles.yesBotton}
                src={yesIcon}
                alt=""
              />
            </>
          ) : (
            <>
              <div
                title={userInfo.nickname || userInfo.login}
                className={styles.header_name}
              >
                {userInfo.nickname || userInfo.login}
              </div>
              <img
                onClick={() => {
                  setShowInput(true);
                  setInfoName(userInfo.nickname || userInfo.login);
                }}
                className={styles.editBotton}
                src={editIcon}
                alt=""
              />
            </>
          )}
        </div>
        <div className={styles.flexInfo}>
          <img src={userIcon} alt="" />
          <div className={styles.uid}>Username: {userInfo?.username}</div>
          <img
            onClick={() => {
              copyText({
                text: `${userInfo?.username}`,
                successText: 'Copied',
              });
            }}
            className={styles.copy}
            src={copyIcon}
            alt=""
          />
        </div>
        <div style={{ marginTop: 12 }}>
          <Button type="link" style={{ padding: 0 }} onClick={() => setPasswordOpen(true)}>
            Change password
          </Button>
        </div>
      </div>
      <Modal
        open={passwordOpen}
        title="Change password"
        onCancel={() => {
          setPasswordOpen(false);
          form.resetFields();
        }}
        footer={null}
        destroyOnClose
      >
        <Form form={form} layout="vertical" onFinish={handleChangePassword}>
          <Form.Item
            label="Current password"
            name="oldPassword"
            rules={[{ required: true, message: 'Please enter current password' }]}
          >
            <Input.Password placeholder="Current password" />
          </Form.Item>
          <Form.Item
            label="New password"
            name="newPassword"
            rules={[
              { required: true, message: 'Please enter new password' },
              { min: 6, message: 'New password must be at least 6 characters' },
            ]}
          >
            <Input.Password placeholder="New password" />
          </Form.Item>
          <Form.Item
            label="Confirm new password"
            name="confirmPassword"
            dependencies={['newPassword']}
            rules={[
              { required: true, message: 'Please confirm new password' },
              ({ getFieldValue }) => ({
                validator(_, value) {
                  if (!value || getFieldValue('newPassword') === value) {
                    return Promise.resolve();
                  }
                  return Promise.reject(new Error('The two passwords do not match'));
                },
              }),
            ]}
          >
            <Input.Password placeholder="Confirm new password" />
          </Form.Item>
          <Button type="primary" htmlType="submit" loading={passwordLoading} block>
            Save password
          </Button>
        </Form>
      </Modal>
    </div>
  );
};

const PersonalCenter: FC<PersonalCenterProps> = ({
  open,
  onCancel,
  mixedChatList,
  onRefreshRecentData,
}) => {
  const [activeIndex, setActiveIndex] = useState(0);
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [itemIdToDelete, setItemIdToDelete] = useState<number | null>(null);
  const navigate = useNavigate();
  const { t } = useTranslation();

  const handleToChat = useCallback(
    (item: PostChatItem) => {
      navigate(`/chat/${item.botId}`);
    },
    [navigate]
  );

  const handleDeleteChat = useCallback(
    (chatListId: number) => {
      deleteChatList({ chatListId })
        .then(() => {
          setDeleteOpen(false);
          message.success(t('commonModal.agentDelete.success'));
          onRefreshRecentData?.();
        })
        .catch(() => {
          setDeleteOpen(false);
          message.error(t('commonModal.agentDelete.failed'));
        });
    },
    [onRefreshRecentData, t]
  );

  const handleDelete = useCallback((item: PostChatItem, e: React.MouseEvent) => {
    e.stopPropagation();
    setItemIdToDelete(item?.id ?? null);
    setDeleteOpen(true);
  }, []);

  const handleDeleteChatConfirm = useCallback(() => {
    if (!itemIdToDelete) {
      return;
    }
    handleDeleteChat(itemIdToDelete);
    setItemIdToDelete(null);
  }, [handleDeleteChat, itemIdToDelete]);

  const handleTabChange = useCallback(
    (index: number) => {
      setActiveIndex(index);
      if (index === 0) {
        onRefreshRecentData();
      }
    },
    [onRefreshRecentData]
  );

  return (
    <Modal
      wrapClassName={styles.open_source_modal}
      width={837}
      open={open}
      centered
      onCancel={onCancel}
      destroyOnClose
      maskClosable={false}
      footer={null}
    >
      <div className={styles.modal_content}>
        <PersonalCenterHeader />
        <div className={styles.content}>
          <TabsHeader
            tabs={tabs}
            activeIndex={activeIndex}
            onTabChange={handleTabChange}
          />
          <div className={styles.contentBox}>
            <Modal
              open={deleteOpen}
              onCancel={() => {
                setDeleteOpen(false);
                setItemIdToDelete(null);
              }}
              closeIcon={null}
              wrapClassName={styles.delete_mode}
              centered
              width={352}
              maskClosable={false}
              onOk={handleDeleteChatConfirm}
            >
              <div className={styles.delete_mode_title}>
                <img src={require('@/assets/imgs/sidebar/warning.svg')} alt="" />
                <span>
                  {activeIndex === 0
                    ? 'Remove this conversation?'
                    : 'Remove this favorite?'}
                </span>
              </div>
            </Modal>
            {activeIndex === 0 ? (
              <RecentUsedList
                recentList={mixedChatList}
                onItemClick={handleToChat}
                onDeleteClick={handleDelete}
              />
            ) : (
              <EmptyState />
            )}
          </div>
        </div>
      </div>
    </Modal>
  );
};

export default PersonalCenter;
